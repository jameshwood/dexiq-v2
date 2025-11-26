# frozen_string_literal: true

module Analysis
  # Deep AI-driven analysis for a single token pair
  # Combines data from multiple sources and uses OpenAI for structured insights
  class TokenPairAnalysisService
    CACHE_TTL = 15.minutes

    def initialize(token, options = {})
      @token = token
      @purchase_price = options[:purchase_price]
      @symbol = options[:symbol] || token.symbol
      @quote_symbol = options[:quote_symbol] || token.quote_symbol
    end

    def analyze
      # Check cache first
      cache_key = "token_pair_analysis:#{@token.id}:#{@purchase_price}"
      cached_result = Rails.cache.read(cache_key)
      return cached_result if cached_result.present?

      # Gather all available data
      snapshots = gather_snapshots

      # Build analysis with OpenAI
      result = perform_ai_analysis(snapshots)

      # Cache the result
      Rails.cache.write(cache_key, result, expires_in: CACHE_TTL)

      result
    end

    private

    def gather_snapshots
      {
        dexscreener: @token.latest_dexscreener_snapshot&.data,
        gecko_terminal: @token.latest_gecko_terminal_snapshot&.data,
        ohlcv_1h: @token.latest_gecko_ohlcv_snapshot('1h')&.data,
        ohlcv_24h: @token.latest_gecko_ohlcv_snapshot('1d')&.data
      }
    end

    def perform_ai_analysis(snapshots)
      # TODO: Implement OpenAI structured analysis
      # For now, return a placeholder structure

      {
        assistant: generate_summary(snapshots),
        insights: generate_insights(snapshots),
        structured_insights: generate_structured_insights(snapshots),
        details: extract_key_details(snapshots),
        snapshots: snapshots
      }
    end

    def generate_summary(snapshots)
      # TODO: Use OpenAI to generate natural language summary
      # Example prompt:
      # "Based on this token data, provide a concise analysis summary:
      #  - Current price action
      #  - Volume and liquidity assessment
      #  - Technical indicators
      #  - Risk factors
      #  - Recommendation
      #
      #  Data: #{snapshots.to_json}"

      "Analysis for #{@symbol}/#{@quote_symbol}. TODO: Implement OpenAI summary generation."
    end

    def generate_insights(snapshots)
      # TODO: Extract specific insights from AI response
      [
        "High volume detected in last 24h",
        "Liquidity is adequate for medium trades",
        "Price momentum is positive"
      ]
    end

    def generate_structured_insights(snapshots)
      # TODO: Use OpenAI with structured output (JSON mode)
      # to return consistent insight objects
      []
    end

    def extract_key_details(snapshots)
      # Extract key metrics from snapshots
      dex_data = snapshots[:dexscreener]
      gecko_data = snapshots[:gecko_terminal]

      {
        current_price: extract_price(dex_data, gecko_data),
        volume_24h: extract_volume(dex_data, gecko_data),
        liquidity: extract_liquidity(dex_data, gecko_data),
        price_change_24h: extract_price_change(dex_data, gecko_data),
        market_cap: extract_market_cap(dex_data, gecko_data)
      }
    end

    def extract_price(dex_data, gecko_data)
      dex_data&.dig('pair', 'priceUsd') || gecko_data&.dig('data', 'attributes', 'price_in_usd')
    end

    def extract_volume(dex_data, gecko_data)
      dex_data&.dig('pair', 'volume', 'h24') || gecko_data&.dig('data', 'attributes', 'volume_usd', 'h24')
    end

    def extract_liquidity(dex_data, gecko_data)
      dex_data&.dig('pair', 'liquidity', 'usd') || gecko_data&.dig('data', 'attributes', 'reserve_in_usd')
    end

    def extract_price_change(dex_data, gecko_data)
      dex_data&.dig('pair', 'priceChange', 'h24') || gecko_data&.dig('data', 'attributes', 'price_percent_change', 'h24')
    end

    def extract_market_cap(dex_data, gecko_data)
      dex_data&.dig('pair', 'fdv') || gecko_data&.dig('data', 'attributes', 'market_cap_usd')
    end
  end
end
