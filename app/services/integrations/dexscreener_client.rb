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
    # @param chain_id [String] e.g., 'ethereum', 'bsc', 'polygon'
    # @param pair_address [String]
    # @return [Hash, nil]
    def fetch_pair(chain_id:, pair_address:)
      path = "/pairs/#{chain_id}/#{pair_address}"
      response = connection.get(path)

      if response.success?
        response.body
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
      path = "/tokens/#{chain_id}/#{token_address}/profile"
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
  end
end
