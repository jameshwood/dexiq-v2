# frozen_string_literal: true

module Presenters
  # Presents token data in a consistent JSON format for API responses
  class TokenPresenter
    def initialize(token, options = {})
      @token = token
      @include_snapshots = options.fetch(:include_snapshots, false)
      @include_readiness = options.fetch(:include_readiness, true)
    end

    def as_json
      base_json.tap do |json|
        json[:readiness] = readiness_data if @include_snapshots
        json[:dex_snapshot] = dexscreener_snapshot if @include_snapshots
        json[:gecko_snapshot] = gecko_terminal_snapshot if @include_snapshots
        json[:ohlcv] = ohlcv_snapshots if @include_snapshots
      end
    end

    private

    def base_json
      {
        id: @token.id,
        chain_id: @token.chain_id,
        pool_address: @token.pool_address,
        symbol: @token.symbol,
        quote_symbol: @token.quote_symbol,
        token_url: @token.token_url,
        created_at: @token.created_at.iso8601,
        updated_at: @token.updated_at.iso8601
      }
    end

    def readiness_data
      Readiness::TokenDataReadinessService.new(@token).data_summary
    end

    def dexscreener_snapshot
      snapshot = @token.latest_dexscreener_snapshot
      return nil unless snapshot

      {
        data: snapshot.data,
        fetched_at: snapshot.fetched_at.iso8601
      }
    end

    def gecko_terminal_snapshot
      snapshot = @token.latest_gecko_terminal_snapshot
      return nil unless snapshot

      {
        data: snapshot.data,
        fetched_at: snapshot.fetched_at.iso8601
      }
    end

    def ohlcv_snapshots
      @token.gecko_ohlcv_snapshots.order(fetched_at: :desc).limit(10).map do |snapshot|
        {
          timeframe: snapshot.timeframe,
          data: snapshot.data,
          fetched_at: snapshot.fetched_at.iso8601
        }
      end
    end
  end
end
