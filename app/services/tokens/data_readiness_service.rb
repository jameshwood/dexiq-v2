# frozen_string_literal: true

module Tokens
  # Service to check if a token has sufficient data for AI analysis
  # Implements tiered data readiness: none, basic, rich
  class DataReadinessService
    def initialize(token)
      @token = token
    end

    def ready_for_analysis?
      base_ready? && ohlcv_ready?
    end

    def base_ready?
      # Must have GeckoTerminal metadata for the base token
      @token.gecko_terminal_snapshots.where(role: 'base').exists?
    end

    def ohlcv_ready?
      # Must have OHLCV data (at least one timeframe)
      @token.gecko_ohlcv_snapshots.exists?
    end

    def data_tier
      return :rich if base_ready? && ohlcv_ready?
      return :basic if @token.dexscreener_snapshots.exists?
      :none
    end

    # Get detailed readiness status
    def status
      {
        tier: data_tier,
        ready_for_analysis: ready_for_analysis?,
        has_dexscreener: @token.dexscreener_snapshots.exists?,
        has_gecko_terminal: base_ready?,
        has_ohlcv: ohlcv_ready?,
        dexscreener_count: @token.dexscreener_snapshots.count,
        gecko_terminal_count: @token.gecko_terminal_snapshots.count,
        ohlcv_count: @token.gecko_ohlcv_snapshots.count
      }
    end
  end
end
