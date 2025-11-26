# frozen_string_literal: true

# Tracks buy and sell transactions for tokens
class PurchaseLog < ApplicationRecord
  belongs_to :token
  belongs_to :user

  TRANSACTION_TYPES = %w[buy sell].freeze

  validates :transaction_type, presence: true, inclusion: { in: TRANSACTION_TYPES }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :price_per_token, presence: true, numericality: { greater_than: 0 }

  scope :buys, -> { where(transaction_type: 'buy') }
  scope :sells, -> { where(transaction_type: 'sell') }
  scope :for_token_and_user, ->(token, user) { where(token: token, user: user).order(created_at: :asc) }

  def buy?
    transaction_type == 'buy'
  end

  def sell?
    transaction_type == 'sell'
  end

  def total_value
    amount * price_per_token
  end

  # Battle-tested P&L calculation methods from v1
  # These methods provide accurate position and profit/loss tracking

  # Class methods for position calculations
  class << self
    # Calculate weighted average buy price for a user's position
    # Uses weighted average method (not FIFO or LIFO)
    def average_buy_price(token, user)
      purchases = for_token_and_user(token, user).buys

      return nil if purchases.empty?

      total_cost = purchases.sum { |p| p.amount * p.price_per_token }
      total_amount = purchases.sum(&:amount)

      return nil if total_amount.zero?

      total_cost / total_amount
    end

    # Calculate current position (tokens held after buys and sells)
    def current_position(token, user)
      transactions = for_token_and_user(token, user)

      total_bought = transactions.buys.sum(&:amount)
      total_sold = transactions.sells.sum(&:amount)

      total_bought - total_sold
    end

    # Calculate total amount invested (still in position)
    def total_invested(token, user)
      transactions = for_token_and_user(token, user)

      total_bought_value = transactions.buys.sum(&:total_value)
      total_sold_value = transactions.sells.sum(&:total_value)

      total_bought_value - total_sold_value
    end

    # Calculate realized P&L (from sells only)
    def realized_pnl(token, user)
      avg_buy = average_buy_price(token, user)
      return 0 if avg_buy.nil?

      sells = for_token_and_user(token, user).sells

      total_realized = sells.sum do |sell|
        # Profit/loss = (sell price - avg buy price) * amount sold
        (sell.price_per_token - avg_buy) * sell.amount
      end

      total_realized
    end

    # Calculate unrealized P&L (for current holdings)
    def unrealized_pnl(token, user, current_price)
      return 0 if current_price.nil? || current_price.zero?

      position = current_position(token, user)
      return 0 if position.zero? || position.negative?

      avg_buy = average_buy_price(token, user)
      return 0 if avg_buy.nil?

      # Unrealized P&L = (current price - avg buy price) * position
      (current_price - avg_buy) * position
    end

    # Calculate total P&L (realized + unrealized)
    def total_pnl(token, user, current_price)
      realized_pnl(token, user) + unrealized_pnl(token, user, current_price)
    end

    # Calculate P&L percentage
    def pnl_percentage(token, user, current_price)
      invested = total_invested(token, user)
      return 0 if invested.zero?

      pnl = total_pnl(token, user, current_price)
      (pnl / invested) * 100
    end

    # Get complete position summary
    def position_summary(token, user, current_price)
      position = current_position(token, user)
      avg_buy = average_buy_price(token, user)
      invested = total_invested(token, user)

      {
        position: position,
        average_buy_price: avg_buy,
        total_invested: invested,
        current_value: position * (current_price || 0),
        realized_pnl: realized_pnl(token, user),
        unrealized_pnl: unrealized_pnl(token, user, current_price),
        total_pnl: total_pnl(token, user, current_price),
        pnl_percentage: pnl_percentage(token, user, current_price),
        current_price: current_price
      }
    end
  end
end
