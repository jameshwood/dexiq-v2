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
      # Battle-tested OpenAI analysis from v1
      details = extract_key_details(snapshots)

      # Build AI prompt with structured context
      prompt = build_ai_prompt(details)

      # Call OpenAI with proven settings from v1
      ai_response = call_openai(prompt)

      {
        assistant: ai_response[:summary],
        insights: ai_response[:insights],
        structured_insights: ai_response[:structured_data],
        details: details,
        snapshots: snapshots
      }
    rescue StandardError => e
      Rails.logger.error("OpenAI analysis failed: #{e.message}")
      # Return structured fallback
      {
        assistant: "Analysis temporarily unavailable for #{@symbol}/#{@quote_symbol}.",
        insights: [],
        structured_insights: {},
        details: extract_key_details(snapshots),
        snapshots: snapshots,
        error: e.message
      }
    end

    def build_ai_prompt(details)
      # Get OHLCV data for technical analysis
      ohlcv_1m = @token.gecko_ohlcv_snapshots
                       .where(timeframe: 'minute', aggregate: 1)
                       .where('timestamp >= ?', 60.minutes.ago.to_i)
                       .order(:timestamp)
                       .limit(60)

      ohlcv_15m = @token.gecko_ohlcv_snapshots
                        .where(timeframe: 'minute', aggregate: 15)
                        .where('timestamp >= ?', 6.hours.ago.to_i)
                        .order(:timestamp)
                        .limit(24)

      # Get latest snapshots for additional context
      dex_snap = @token.latest_dexscreener_snapshot
      gecko_snap = @token.latest_gecko_terminal_snapshot('base')

      # Calculate buy/sell ratio
      buy_sell_ratio = dex_snap&.buy_sell_ratio('24h')

      # Build comprehensive prompt with all data
      <<~PROMPT
        You are a cryptocurrency analyst specializing in DeFi tokens and decentralized exchange (DEX) trading.
        Your role is to provide concise, actionable analysis for traders making quick decisions.

        CONTEXT:
        Token Pair: #{@symbol}/#{@quote_symbol}
        Current Price: $#{details[:current_price]}
        24h Volume: $#{details[:volume_24h]}
        Liquidity: $#{details[:liquidity]}
        Market Cap: $#{details[:market_cap]}
        #{@purchase_price ? "User Purchase Price: $#{@purchase_price}" : ""}

        PRICE MOMENTUM:
        - 5m: #{dex_snap&.price_change_5m}%
        - 1h: #{dex_snap&.price_change_1h}%
        - 6h: #{dex_snap&.price_change_6h}%
        - 24h: #{details[:price_change_24h]}%

        TRANSACTION ACTIVITY:
        - Buys (24h): #{dex_snap&.txns_24h&.dig('buys')}
        - Sells (24h): #{dex_snap&.txns_24h&.dig('sells')}
        - Buy/Sell Ratio: #{buy_sell_ratio&.round(2) || 'N/A'}

        TOKEN METADATA:
        - Holders: #{gecko_snap&.holders_count || 'Unknown'}
        - Top 10 Concentration: #{gecko_snap&.holders_top_10 || 'Unknown'} (concentration risk)
        - GT Score: #{gecko_snap&.gt_score || 'N/A'}/100
        - Mint Authority: #{gecko_snap&.mint_authority || 'Unknown'} (rug pull risk)
        #{gecko_snap&.twitter_handle ? "- Social: Twitter @#{gecko_snap.twitter_handle}" : ""}

        TECHNICAL ANALYSIS (OHLCV):
        - Recent 1-min candles (#{ohlcv_1m.count}): #{format_ohlcv_for_ai(ohlcv_1m)}
        - Recent 15-min candles (#{ohlcv_15m.count}): #{format_ohlcv_for_ai(ohlcv_15m)}

        TASK:
        Provide a comprehensive analysis covering:

        1. PRICE ACTION & MOMENTUM
           - Current trend direction and strength
           - Key support and resistance levels if identifiable
           - Momentum indicators from OHLCV data

        2. VOLUME & LIQUIDITY ANALYSIS
           - Is volume healthy relative to market cap?
           - Is liquidity sufficient for trading?
           - Buy/sell pressure analysis
           - Any anomalies or red flags?

        3. RISK ASSESSMENT
           - Liquidity risk (rug pull potential based on mint authority)
           - Holder concentration risk
           - Volatility assessment from OHLCV patterns
           - Market maturity
           - Any warning signs

        4. TRADING RECOMMENDATION
           - For existing holders: Hold, take profits, or exit?
           - For new entries: Good entry point or wait?
           - Position sizing suggestion (conservative/moderate/aggressive)

        5. KEY INSIGHTS (3-5 bullet points)
           - Most critical facts a trader should know
           - Unique characteristics of this token
           - Time-sensitive opportunities or risks

        Provide your analysis in a clear, structured format. Be honest about uncertainties.
        Prioritize actionable insights over generic commentary.
      PROMPT
    end

    def format_ohlcv_for_ai(ohlcv_records)
      return "No data available" if ohlcv_records.empty?

      # Convert to compact format for AI (last 5 candles for brevity)
      ohlcv_records.last(5).map do |candle|
        "#{Time.at(candle.timestamp).strftime('%H:%M')} O:#{candle.open} H:#{candle.high} L:#{candle.low} C:#{candle.close} V:#{candle.volume}"
      end.join("\n")
    end

    def call_openai(prompt)
      # Battle-tested OpenAI settings from v1
      client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))

      response = client.chat(
        parameters: {
          model: 'gpt-4o', # Proven model from v1
          messages: [
            { role: 'system', content: 'You are a professional cryptocurrency analyst specializing in DeFi and DEX trading.' },
            { role: 'user', content: prompt }
          ],
          temperature: 0.7, # Balanced creativity and consistency from v1
          max_tokens: 2000 # Sufficient for comprehensive analysis
        }
      )

      content = response.dig('choices', 0, 'message', 'content')

      # Parse the response into structured components
      parse_ai_response(content)
    end

    def parse_ai_response(content)
      # Extract sections from AI response
      {
        summary: content,
        insights: extract_bullet_points(content),
        structured_data: {
          raw_analysis: content,
          model: 'gpt-4o',
          timestamp: Time.current.iso8601
        }
      }
    end

    def extract_bullet_points(content)
      # Extract key insights as bullet points
      insights = []
      content.scan(/^[-•]\s*(.+)$/).each do |match|
        insights << match[0].strip
      end

      # Fallback: split by numbered points
      if insights.empty?
        content.scan(/^\d+\.\s+(.+)$/).each do |match|
          insights << match[0].strip
        end
      end

      insights.take(5) # Limit to top 5 insights
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
