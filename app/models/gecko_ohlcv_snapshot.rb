# frozen_string_literal: true

# Stores GeckoTerminal OHLCV (candlestick) data for AI training and technical analysis
class GeckoOhlcvSnapshot < ApplicationRecord
  belongs_to :token

  VALID_TIMEFRAMES = %w[minute hour day].freeze

  # Validations
  validates :token, presence: true
  validates :timeframe, inclusion: { in: VALID_TIMEFRAMES }
  validates :aggregate, presence: true
  validates :timestamp, presence: true, uniqueness: { scope: [:token_id, :timeframe, :aggregate] }

  # Scopes for querying
  scope :for_token, ->(token) { where(token: token) }
  scope :for_timeframe, ->(timeframe, aggregate) { where(timeframe: timeframe, aggregate: aggregate) }
  scope :since, ->(timestamp) { where('timestamp >= ?', timestamp) }
  scope :recent, ->(limit = 100) { order(timestamp: :desc).limit(limit) }

  # Helper method to get candle data as hash
  def to_ohlcv_hash
    {
      timestamp: timestamp,
      time: Time.at(timestamp),
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume
    }
  end

  # Calculate price change percentage for this candle
  def price_change_pct
    return 0 if open.nil? || open.zero?
    ((close - open) / open) * 100
  end

  # Check if candle is bullish (close > open)
  def bullish?
    close > open
  end

  # Check if candle is bearish (close < open)
  def bearish?
    close < open
  end
end
