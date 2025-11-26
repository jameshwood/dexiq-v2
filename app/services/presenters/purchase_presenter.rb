# frozen_string_literal: true

module Presenters
  # Presents purchase log data with position and P&L calculations
  class PurchasePresenter
    def initialize(token, user)
      @token = token
      @user = user
    end

    def as_json
      {
        purchases: purchases_json,
        current_position: current_position_json,
        pnl: pnl_json
      }
    end

    private

    def purchases_json
      purchase_logs.map do |log|
        {
          id: log.id,
          transaction_type: log.transaction_type,
          amount: log.amount.to_f,
          price_per_token: log.price_per_token.to_f,
          total_value: log.total_value.to_f,
          transaction_hash: log.transaction_hash,
          notes: log.notes,
          created_at: log.created_at.iso8601
        }
      end
    end

    def current_position_json
      position = calculate_position

      {
        total_bought: position[:total_bought].to_f,
        total_sold: position[:total_sold].to_f,
        current_amount: position[:current_amount].to_f,
        average_buy_price: position[:average_buy_price].to_f,
        total_invested: position[:total_invested].to_f
      }
    end

    def pnl_json
      position = calculate_position
      current_price = fetch_current_price

      return nil unless current_price && position[:current_amount] > 0

      current_value = position[:current_amount] * current_price
      pnl_amount = current_value - position[:total_invested]
      pnl_percent = (pnl_amount / position[:total_invested]) * 100

      {
        current_price: current_price.to_f,
        current_value: current_value.to_f,
        pnl_amount: pnl_amount.to_f,
        pnl_percent: pnl_percent.round(2)
      }
    end

    def purchase_logs
      @purchase_logs ||= PurchaseLog.for_token_and_user(@token, @user)
    end

    def calculate_position
      buys = purchase_logs.buys
      sells = purchase_logs.sells

      total_bought = buys.sum(&:amount)
      total_sold = sells.sum(&:amount)
      current_amount = total_bought - total_sold

      total_buy_value = buys.sum { |log| log.amount * log.price_per_token }
      average_buy_price = total_bought > 0 ? total_buy_value / total_bought : 0

      total_sell_value = sells.sum { |log| log.amount * log.price_per_token }
      total_invested = total_buy_value - total_sell_value

      {
        total_bought: total_bought,
        total_sold: total_sold,
        current_amount: current_amount,
        average_buy_price: average_buy_price,
        total_invested: total_invested
      }
    end

    def fetch_current_price
      # Try to get current price from latest snapshot
      dex_snapshot = @token.latest_dexscreener_snapshot
      gecko_snapshot = @token.latest_gecko_terminal_snapshot

      price = dex_snapshot&.data&.dig('pair', 'priceUsd') ||
              gecko_snapshot&.data&.dig('data', 'attributes', 'price_in_usd')

      price&.to_f
    end
  end
end
