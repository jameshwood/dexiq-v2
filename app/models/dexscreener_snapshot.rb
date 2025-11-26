# frozen_string_literal: true

# Stores structured DexScreener API data for time-series analysis
class DexscreenerSnapshot < ApplicationRecord
  belongs_to :token

  # Validations
  validates :token, presence: true
  validates :captured_at, presence: true

  # Set captured_at automatically
  before_validation :set_captured_at, on: :create

  # Scopes for querying
  scope :recent, -> { order(created_at: :desc) }
  scope :for_token, ->(token) { where(token: token) }
  scope :since, ->(time) { where('created_at >= ?', time) }

  # Calculate buy/sell ratio from transaction data
  def buy_sell_ratio(timeframe = '24h')
    txns = send("txns_#{timeframe}")
    return nil unless txns.present?

    buys = txns['buys'].to_f
    sells = txns['sells'].to_f

    return nil if sells.zero?
    buys / sells
  end

  # Total transactions for a timeframe
  def total_txns(timeframe = '24h')
    txns = send("txns_#{timeframe}")
    return 0 unless txns.present?

    (txns['buys'].to_i + txns['sells'].to_i)
  end

  private

  def set_captured_at
    self.captured_at ||= Time.current
  end
end
