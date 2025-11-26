# frozen_string_literal: true

# Faraday HTTP client configuration
# Default middleware stack for external API integrations

require 'faraday'
require 'faraday/retry'

# Default Faraday connection configuration
Faraday.default_connection_options = Faraday::ConnectionOptions.new.tap do |options|
  options.request.timeout = 30      # open/read timeout in seconds
  options.request.open_timeout = 10 # connection open timeout
end

# Default adapter
Faraday.default_adapter = :net_http

# Custom middleware stack for external integrations
module FaradayHelpers
  def self.default_middleware
    Proc.new do |conn|
      # Retry configuration
      conn.request :retry, {
        max: 3,
        interval: 0.5,
        interval_randomness: 0.5,
        backoff_factor: 2,
        retry_statuses: [429, 500, 502, 503, 504],
        methods: [:get, :post],
        retry_if: ->(env, exception) {
          # Retry on timeout and connection errors
          exception.is_a?(Faraday::TimeoutError) ||
          exception.is_a?(Faraday::ConnectionFailed)
        }
      }

      # JSON encoding/decoding
      conn.request :json
      conn.response :json, content_type: /\bjson$/

      # Logging in development
      if Rails.env.development?
        conn.response :logger, Rails.logger, { headers: true, bodies: true }
      end

      conn.adapter Faraday.default_adapter
    end
  end
end
