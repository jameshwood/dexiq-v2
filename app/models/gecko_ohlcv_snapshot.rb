# frozen_string_literal: true

# Stores GeckoTerminal OHLCV (price candle) data for a token
class GeckoOhlcvSnapshot < ApplicationRecord
  belongs_to :token

  VALID_TIMEFRAMES = %w[1m 5m 15m 1h 4h 1d 1w].freeze

  validates :data, presence: true
  validates :fetched_at, presence: true
  validates :timeframe, inclusion: { in: VALID_TIMEFRAMES }, allow_nil: true

  before_validation :set_fetched_at, on: :create

  private

  def set_fetched_at
    self.fetched_at ||= Time.current
  end
end
