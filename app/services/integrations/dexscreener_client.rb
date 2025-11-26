# frozen_string_literal: true

module Integrations
  # HTTP client for DexScreener API
  # Docs: https://docs.dexscreener.com/api/reference
  class DexscreenerClient
    BASE_URL = 'https://api.dexscreener.com/latest/dex'

    attr_reader :connection

    def initialize
      @connection = Faraday.new(url: BASE_URL) do |conn|
        FaradayHelpers.default_middleware.call(conn)
        conn.headers['Accept'] = 'application/json'
      end
    end

    # Fetch pair data by chain and pair address
    # Battle-tested from v1 - proven endpoint structure
    # @param chain_id [String] e.g., 'ethereum', 'bsc', 'polygon'
    # @param pair_address [String]
    # @return [Hash, nil] Structured data ready for DexscreenerSnapshot
    def fetch_pair(chain_id:, pair_address:)
      # Normalize chain ID (DexScreener uses lowercase)
      normalized_chain = normalize_chain_id(chain_id)

      path = "/pairs/#{normalized_chain}/#{pair_address}"
      response = connection.get(path)

      if response.success?
        data = response.body
        # DexScreener returns { pairs: [...] }
        # Return the first pair if available
        pairs = data.is_a?(Hash) ? data['pairs'] : []
        raw_pair = pairs&.first

        return nil unless raw_pair

        # Parse into structured format for database
        parse_pair_data(raw_pair)
      else
        Rails.logger.error("DexScreener API error: #{response.status} - #{response.body}")
        nil
      end
    rescue Faraday::Error => e
      Rails.logger.error("DexScreener connection error: #{e.class} - #{e.message}")
      nil
    end

    # Search for pairs by token address
    # @param token_address [String]
    # @return [Hash, nil]
    def search_by_token(token_address:)
      path = "/tokens/#{token_address}"
      response = connection.get(path)

      if response.success?
        response.body
      else
        Rails.logger.error("DexScreener search error: #{response.status} - #{response.body}")
        nil
      end
    rescue Faraday::Error => e
      Rails.logger.error("DexScreener search connection error: #{e.class} - #{e.message}")
      nil
    end

    # Get latest token profiles (optional, if using profile endpoint)
    # @param chain_id [String]
    # @param token_address [String]
    # @return [Hash, nil]
    def fetch_token_profile(chain_id:, token_address:)
      normalized_chain = normalize_chain_id(chain_id)

      path = "/tokens/#{normalized_chain}/#{token_address}/profile"
      response = connection.get(path)

      if response.success?
        response.body
      else
        Rails.logger.error("DexScreener profile error: #{response.status} - #{response.body}")
        nil
      end
    rescue Faraday::Error => e
      Rails.logger.error("DexScreener profile connection error: #{e.class} - #{e.message}")
      nil
    end

    private

    # Parse raw DexScreener API response into structured format
    def parse_pair_data(pair)
      {
        chain_id: pair['chainId'],
        dex_id: pair['dexId'],
        url: pair['url'],
        price_usd: pair['priceUsd'],
        price_native: pair['priceNative'],
        txns_5m: pair.dig('txns', 'm5'),
        txns_1h: pair.dig('txns', 'h1'),
        txns_6h: pair.dig('txns', 'h6'),
        txns_24h: pair.dig('txns', 'h24'),
        volume_5m: pair.dig('volume', 'm5'),
        volume_1h: pair.dig('volume', 'h1'),
        volume_6h: pair.dig('volume', 'h6'),
        volume_24h: pair.dig('volume', 'h24'),
        price_change_5m: pair.dig('priceChange', 'm5'),
        price_change_1h: pair.dig('priceChange', 'h1'),
        price_change_6h: pair.dig('priceChange', 'h6'),
        price_change_24h: pair.dig('priceChange', 'h24'),
        liquidity_usd: pair.dig('liquidity', 'usd'),
        liquidity_base: pair.dig('liquidity', 'base'),
        liquidity_quote: pair.dig('liquidity', 'quote'),
        fdv: pair['fdv'],
        market_cap: pair['marketCap'],
        pair_created_at: parse_timestamp(pair['pairCreatedAt'])
      }
    end

    # Parse timestamp (milliseconds or seconds)
    def parse_timestamp(timestamp)
      return nil unless timestamp

      # DexScreener returns milliseconds
      Time.at(timestamp / 1000.0)
    rescue StandardError => e
      Rails.logger.error("Failed to parse timestamp #{timestamp}: #{e.message}")
      nil
    end

    # Normalize chain IDs to DexScreener format
    # Battle-tested mappings from v1
    def normalize_chain_id(chain_id)
      mappings = {
        'eth' => 'ethereum',
        'bsc' => 'bsc',
        'bnb' => 'bsc',
        'polygon' => 'polygon',
        'matic' => 'polygon',
        'arbitrum' => 'arbitrum',
        'optimism' => 'optimism',
        'avalanche' => 'avalanche',
        'avax' => 'avalanche',
        'fantom' => 'fantom',
        'ftm' => 'fantom',
        'solana' => 'solana',
        'sol' => 'solana',
        'base' => 'base'
      }

      normalized = mappings[chain_id.to_s.downcase] || chain_id.to_s.downcase
      normalized
    end
  end
end
