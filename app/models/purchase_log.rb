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
end
