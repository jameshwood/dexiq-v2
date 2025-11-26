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
    # Battle-tested from v1 - proven endpoint structure
    # @param network [String] e.g., 'eth', 'bsc', 'polygon'
    # @param pool_address [String] the pool/pair address
    # @return [Hash, nil] Structured data ready for GeckoTerminalSnapshot
    def fetch_pool(network:, pool_address:)
      # Normalize network name (GeckoTerminal uses specific formats)
      normalized_network = normalize_network_id(network)

      path = "/networks/#{normalized_network}/pools/#{pool_address}"
      response = connection.get(path)

      if response.success?
        # GeckoTerminal returns { data: {...}, included: [...] }
        raw_data = response.body
        return nil unless raw_data && raw_data['data']

        # Parse into structured format for database
        parse_pool_data(raw_data)
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
      normalized_network = normalize_network_id(network)

      path = "/networks/#{normalized_network}/pools/#{pool_address}/ohlcv/#{timeframe}"
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

    private

    # Parse raw GeckoTerminal API response into structured format
    # Returns an array with base and quote token data
    def parse_pool_data(response)
      # Extract base and quote token from included relationships
      included = response['included'] || []
      base_token_data = included.find { |item| item['type'] == 'token' && item.dig('attributes', 'symbol') }
      quote_token_data = included.find { |item| item['type'] == 'token' && item['id'] != base_token_data&.dig('id') }

      results = []

      # Parse base token if available
      if base_token_data
        results << parse_token_data(base_token_data, 'base')
      end

      # Parse quote token if available
      if quote_token_data
        results << parse_token_data(quote_token_data, 'quote')
      end

      results
    end

    # Parse individual token data from GeckoTerminal response
    def parse_token_data(token, role)
      attrs = token['attributes'] || {}

      {
        role: role,
        address: attrs['address'],
        name: attrs['name'],
        symbol: attrs['symbol'],
        decimals: attrs['decimals'],
        coingecko_coin_id: attrs['coingecko_coin_id'],
        image_large: attrs.dig('image_url'),
        image_small: attrs.dig('image_url'),
        image_thumb: attrs.dig('image_url'),
        description: attrs['description'],
        twitter_handle: attrs.dig('websites', 0, 'label') == 'Twitter' ? attrs.dig('websites', 0, 'url')&.split('/')&.last : nil,
        discord_url: attrs.dig('websites')&.find { |w| w['label'] == 'Discord' }&.dig('url'),
        telegram_handle: attrs.dig('websites')&.find { |w| w['label'] == 'Telegram' }&.dig('url')&.split('/')&.last,
        gt_score: attrs['gt_score'],
        holders_count: attrs.dig('total_supply'),  # Approximate
        holders_top_10: nil,  # Not in basic pool endpoint
        holders_11_20: nil,
        holders_21_40: nil,
        holders_rest: nil,
        mint_authority: attrs['mint_authority'],
        freeze_authority: attrs['freeze_authority']
      }
    end

    # Normalize network IDs to GeckoTerminal format
    # Battle-tested mappings from v1
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

      normalized = mappings[network.to_s.downcase] || network.to_s.downcase
      normalized
    end
  end
end
