# frozen_string_literal: true

# Background job to fetch external data for a token
# Orchestrates calls to DexScreener, GeckoTerminal, and OHLCV APIs
# Broadcasts readiness via ActionCable when complete
class FetchTokenDataJob < ApplicationJob
  queue_as :default

  retry_on Faraday::Error, wait: :exponentially_longer, attempts: 3
  retry_on StandardError, wait: 5.seconds, attempts: 2

  def perform(token_id)
    token = Token.find(token_id)

    Rails.logger.info("FetchTokenDataJob: Starting data fetch for token #{token.id}")

    # Fetch from multiple sources
    fetch_dexscreener_data(token)
    fetch_gecko_terminal_data(token)
    fetch_ohlcv_data(token)

    # Calculate readiness tier
    tier = token.data_readiness_tier

    # Broadcast readiness to ActionCable subscribers
    TokenStatusChannel.broadcast_readiness(
      token,
      tier: tier,
      data: {
        has_dexscreener: token.latest_dexscreener_snapshot.present?,
        has_gecko_terminal: token.latest_gecko_terminal_snapshot.present?,
        has_ohlcv: token.gecko_ohlcv_snapshots.exists?
      }
    )

    Rails.logger.info("FetchTokenDataJob: Completed for token #{token.id}, tier: #{tier}")
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("FetchTokenDataJob: Token not found - #{e.message}")
  rescue => e
    Rails.logger.error("FetchTokenDataJob: Failed for token #{token_id} - #{e.class}: #{e.message}")
    TokenStatusChannel.broadcast_error(token, error: e.message) if token
    raise
  end

  private

  def fetch_dexscreener_data(token)
    client = Integrations::DexscreenerClient.new
    data = client.fetch_pair(chain_id: token.chain_id, pair_address: token.pool_address)

    if data.present?
      token.dexscreener_snapshots.create!(data: data, fetched_at: Time.current)
      Rails.logger.info("FetchTokenDataJob: DexScreener data saved for token #{token.id}")
    else
      Rails.logger.warn("FetchTokenDataJob: No DexScreener data for token #{token.id}")
    end
  rescue => e
    Rails.logger.error("FetchTokenDataJob: DexScreener fetch failed - #{e.message}")
  end

  def fetch_gecko_terminal_data(token)
    client = Integrations::GeckoTerminalClient.new

    # Client handles network normalization with battle-tested mappings from v1
    data = client.fetch_pool(network: token.chain_id, pool_address: token.pool_address)

    if data.present?
      token.gecko_terminal_snapshots.create!(data: data, fetched_at: Time.current)
      Rails.logger.info("FetchTokenDataJob: GeckoTerminal data saved for token #{token.id}")
    else
      Rails.logger.warn("FetchTokenDataJob: No GeckoTerminal data for token #{token.id}")
    end
  rescue => e
    Rails.logger.error("FetchTokenDataJob: GeckoTerminal fetch failed - #{e.message}")
  end

  def fetch_ohlcv_data(token)
    client = Integrations::GeckoTerminalClient.new

    # Fetch multiple timeframes (battle-tested approach from v1)
    timeframes = ['1h', '1d']

    timeframes.each do |timeframe|
      data = client.fetch_ohlcv(
        network: token.chain_id,
        pool_address: token.pool_address,
        timeframe: timeframe,
        limit: 100
      )

      if data.present?
        token.gecko_ohlcv_snapshots.create!(
          data: data,
          timeframe: timeframe,
          fetched_at: Time.current
        )
        Rails.logger.info("FetchTokenDataJob: OHLCV #{timeframe} data saved for token #{token.id}")
      end
    end
  rescue => e
    Rails.logger.error("FetchTokenDataJob: OHLCV fetch failed - #{e.message}")
  end
end
