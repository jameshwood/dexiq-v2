# frozen_string_literal: true

module Integrations
  # HTTP client for GeckoTerminal OHLCV (candlestick) data
  # Implements incremental fetching to avoid re-downloading historical data
  class GeckoOhlcvClient
    BASE_URL = 'https://api.geckoterminal.com/api/v2'

    attr_reader :chain_id, :pool_address, :token, :connection

    def initialize(chain_id, pool_address, token)
      @chain_id = normalize_network_id(chain_id)
      @pool_address = pool_address
      @token = token

      @connection = Faraday.new(url: BASE_URL) do |conn|
        FaradayHelpers.default_middleware.call(conn)
        conn.headers['Accept'] = 'application/json;version=20230302'
      end
    end

    # Fetch all timeframes for AI training
    def fetch_all_timeframes
      fetch_ohlcv('minute', 1)   # 1-min candles (live trading feedback)
      fetch_ohlcv('minute', 15)  # 15-min candles (short-term patterns)
      fetch_ohlcv('hour', 4)     # 4-hour candles (mid-term trends)
      fetch_ohlcv('day', 1)      # Daily candles (long-term trends)
    end

    # Fetch specific timeframe with incremental updates
    def fetch_ohlcv(timeframe, aggregate)
      # Find latest snapshot to avoid re-fetching
      latest_snapshot = @token.gecko_ohlcv_snapshots
                              .where(timeframe: timeframe, aggregate: aggregate)
                              .order(timestamp: :desc)
                              .first

      # Start from after latest timestamp (incremental)
      from_timestamp = latest_snapshot ? latest_snapshot.timestamp.to_i + 1 : nil

      endpoint = "/networks/#{@chain_id}/pools/#{@pool_address}/ohlcv/#{timeframe}"

      params = {
        before_timestamp: Time.now.to_i,
        limit: 1000,  # Max per request
        currency: 'usd',
        token: 'base',
        include_empty_intervals: false,
        aggregate: aggregate
      }

      # Add from_timestamp for incremental fetch
      params[:from_timestamp] = from_timestamp if from_timestamp

      response = connection.get(endpoint, params)

      return nil unless response.success?

      ohlcv_list = response.body.dig('data', 'attributes', 'ohlcv_list')
      return nil unless ohlcv_list.present?

      # Batch insert (efficient for large datasets)
      records = ohlcv_list.map do |entry|
        {
          token_id: @token.id,
          timeframe: timeframe,
          aggregate: aggregate,
          timestamp: entry[0],
          open: entry[1],
          high: entry[2],
          low: entry[3],
          close: entry[4],
          volume: entry[5],
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # Insert only new records (skip duplicates)
      if records.any?
        GeckoOhlcvSnapshot.insert_all(
          records,
          unique_by: [:token_id, :timeframe, :aggregate, :timestamp]
        )

        Rails.logger.info("Fetched #{records.size} #{timeframe}/#{aggregate} candles for token #{@token.id}")
      end

      records.size
    rescue Faraday::Error => e
      Rails.logger.error("OHLCV fetch error (#{timeframe}/#{aggregate}): #{e.class} - #{e.message}")
      nil
    rescue StandardError => e
      Rails.logger.error("OHLCV processing error (#{timeframe}/#{aggregate}): #{e.class} - #{e.message}")
      nil
    end

    private

    # Normalize network IDs to GeckoTerminal format
    def normalize_network_id(network)
      mappings = {
        'ethereum' => 'eth',
        'eth' => 'eth',
        'bsc' => 'bsc',
        'bnb' => 'bsc',
        'binance-smart-chain' => 'bsc',
        'polygon' => 'polygon',
        'matic' => 'polygon',
        'arbitrum' => 'arbitrum',
        'arbitrum-one' => 'arbitrum',
        'optimism' => 'optimism',
        'avalanche' => 'avalanche',
        'avax' => 'avalanche',
        'fantom' => 'fantom',
        'ftm' => 'fantom',
        'solana' => 'solana',
        'sol' => 'solana',
        'base' => 'base'
      }

      mappings[network.to_s.downcase] || network.to_s.downcase
    end
  end
end
