# frozen_string_literal: true

module Readiness
  # Determines how much data is available for a token
  # Returns tier: "none", "some", or "lots"
  class TokenDataReadinessService
    def initialize(token)
      @token = token
    end

    def calculate_tier
      data_sources = count_available_sources

      return "none" if data_sources == 0
      return "some" if data_sources.between?(1, 2)
      "lots"
    end

    def data_summary
      {
        tier: calculate_tier,
        has_dexscreener: dexscreener_available?,
        has_gecko_terminal: gecko_terminal_available?,
        has_ohlcv: ohlcv_available?,
        last_updated: most_recent_fetch_time
      }
    end

    private

    def count_available_sources
      count = 0
      count += 1 if dexscreener_available?
      count += 1 if gecko_terminal_available?
      count += 1 if ohlcv_available?
      count
    end

    def dexscreener_available?
      @token.latest_dexscreener_snapshot.present?
    end

    def gecko_terminal_available?
      @token.latest_gecko_terminal_snapshot.present?
    end

    def ohlcv_available?
      @token.gecko_ohlcv_snapshots.exists?
    end

    def most_recent_fetch_time
      times = [
        @token.latest_dexscreener_snapshot&.fetched_at,
        @token.latest_gecko_terminal_snapshot&.fetched_at,
        @token.gecko_ohlcv_snapshots.maximum(:fetched_at)
      ].compact

      times.max
    end
  end
end
