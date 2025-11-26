# frozen_string_literal: true

module Tokens
  # Background job to orchestrate fetching all external data for a token
  # Fetches from DexScreener, GeckoTerminal, and OHLCV APIs
  # Triggers AI analysis when data is ready
  class FetchDataJob < ApplicationJob
    queue_as :default

    def perform(token_id)
      token = Token.find(token_id)

      # Step 1: Fetch DexScreener data (if stale or missing)
      fetch_dexscreener_data(token)

      # Step 2: Fetch GeckoTerminal metadata (if stale or missing)
      fetch_geckoterminal_data(token)

      # Step 3: Fetch OHLCV data (always fetch latest)
      fetch_ohlcv_data(token)

      # Step 4: Check if ready for AI analysis
      if data_ready_for_analysis?(token)
        # Trigger AI analysis job
        Tokens::AnalyzeJob.perform_later(token.id)
      else
        Rails.logger.warn("Token #{token.id} data not ready for analysis yet")
      end
    end

    private

    def fetch_dexscreener_data(token)
      last_snapshot = token.dexscreener_snapshots.order(created_at: :desc).first

      # Fetch if missing or older than 5 minutes
      if last_snapshot.nil? || last_snapshot.created_at < 5.minutes.ago
        Rails.logger.info("Fetching DexScreener data for token #{token.id}")

        client = Integrations::DexscreenerClient.new
        data = client.fetch_pair(chain_id: token.chain_id, pair_address: token.pool_address)

        if data
          DexscreenerSnapshot.create!(
            token: token,
            chain_id: data[:chain_id] || token.chain_id,
            dex_id: data[:dex_id],
            url: data[:url],
            price_usd: data[:price_usd],
            price_native: data[:price_native],
            txns_5m: data[:txns_5m],
            txns_1h: data[:txns_1h],
            txns_6h: data[:txns_6h],
            txns_24h: data[:txns_24h],
            volume_5m: data[:volume_5m],
            volume_1h: data[:volume_1h],
            volume_6h: data[:volume_6h],
            volume_24h: data[:volume_24h],
            price_change_5m: data[:price_change_5m],
            price_change_1h: data[:price_change_1h],
            price_change_6h: data[:price_change_6h],
            price_change_24h: data[:price_change_24h],
            liquidity_usd: data[:liquidity_usd],
            liquidity_base: data[:liquidity_base],
            liquidity_quote: data[:liquidity_quote],
            fdv: data[:fdv],
            market_cap: data[:market_cap],
            pair_created_at: data[:pair_created_at],
            captured_at: Time.current
          )
        end
      end
    end

    def fetch_geckoterminal_data(token)
      last_snapshot = token.gecko_terminal_snapshots.order(created_at: :desc).first

      if last_snapshot.nil? || last_snapshot.created_at < 5.minutes.ago
        Rails.logger.info("Fetching GeckoTerminal data for token #{token.id}")

        client = Integrations::GeckoTerminalClient.new
        tokens_data = client.fetch_pool(network: token.chain_id, pool_address: token.pool_address)

        if tokens_data && tokens_data.is_a?(Array)
          tokens_data.each do |token_data|
            GeckoTerminalSnapshot.create!(
              token: token,
              address: token_data[:address],
              name: token_data[:name],
              symbol: token_data[:symbol],
              role: token_data[:role],  # 'base' or 'quote'
              decimals: token_data[:decimals],
              coingecko_coin_id: token_data[:coingecko_coin_id],
              image_large: token_data[:image_large],
              image_small: token_data[:image_small],
              image_thumb: token_data[:image_thumb],
              description: token_data[:description],
              twitter_handle: token_data[:twitter_handle],
              discord_url: token_data[:discord_url],
              telegram_handle: token_data[:telegram_handle],
              gt_score: token_data[:gt_score],
              holders_count: token_data[:holders_count],
              holders_top_10: token_data[:holders_top_10],
              holders_11_20: token_data[:holders_11_20],
              holders_21_40: token_data[:holders_21_40],
              holders_rest: token_data[:holders_rest],
              mint_authority: token_data[:mint_authority],
              freeze_authority: token_data[:freeze_authority]
            )
          end
        end
      end
    end

    def fetch_ohlcv_data(token)
      Rails.logger.info("Fetching OHLCV data for token #{token.id}")

      client = Integrations::GeckoOhlcvClient.new(
        token.chain_id,
        token.pool_address,
        token
      )

      # Fetch all timeframes (incremental, so it's efficient)
      client.fetch_all_timeframes
    end

    def data_ready_for_analysis?(token)
      # Must have both GeckoTerminal metadata AND OHLCV data
      has_gecko_metadata = token.gecko_terminal_snapshots.where(role: 'base').exists?
      has_ohlcv_data = token.gecko_ohlcv_snapshots.exists?

      has_gecko_metadata && has_ohlcv_data
    end
  end
end
