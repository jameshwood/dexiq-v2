# frozen_string_literal: true

module Integrations
  # HTTP client for GeckoTerminal API
  # Docs: https://www.geckoterminal.com/dex-api
  class GeckoTerminalClient
    BASE_URL = 'https://api.geckoterminal.com/api/v2'

    attr_reader :connection

    def initialize
      @connection = Faraday.new(url: BASE_URL) do |conn|
        FaradayHelpers.default_middleware.call(conn)
        conn.headers['Accept'] = 'application/json'
      end
    end

    # Fetch network and pool data for a specific pool
    # @param network [String] e.g., 'eth', 'bsc', 'polygon'
    # @param pool_address [String] the pool/pair address
    # @return [Hash, nil] parsed response or nil on error
    def fetch_pool(network:, pool_address:)
      path = "/networks/#{network}/pools/#{pool_address}"
      response = connection.get(path)

      if response.success?
        response.body
      else
        Rails.logger.error("GeckoTerminal API error: #{response.status} - #{response.body}")
        nil
      end
    rescue Faraday::Error => e
      Rails.logger.error("GeckoTerminal connection error: #{e.class} - #{e.message}")
      nil
    end

    # Fetch OHLCV data for a pool
    # @param network [String]
    # @param pool_address [String]
    # @param timeframe [String] e.g., '1m', '5m', '1h', '1d'
    # @param limit [Integer] number of candles
    # @return [Hash, nil]
    def fetch_ohlcv(network:, pool_address:, timeframe: '1h', limit: 100)
      path = "/networks/#{network}/pools/#{pool_address}/ohlcv/#{timeframe}"
      response = connection.get(path, { limit: limit })

      if response.success?
        response.body
      else
        Rails.logger.error("GeckoTerminal OHLCV error: #{response.status} - #{response.body}")
        nil
      end
    rescue Faraday::Error => e
      Rails.logger.error("GeckoTerminal OHLCV connection error: #{e.class} - #{e.message}")
      nil
    end

    # Search for tokens
    # @param query [String] search term
    # @return [Hash, nil]
    def search_tokens(query:)
      path = "/search/pools"
      response = connection.get(path, { query: query })

      if response.success?
        response.body
      else
        Rails.logger.error("GeckoTerminal search error: #{response.status} - #{response.body}")
        nil
      end
    rescue Faraday::Error => e
      Rails.logger.error("GeckoTerminal search connection error: #{e.class} - #{e.message}")
      nil
    end
  end
end
