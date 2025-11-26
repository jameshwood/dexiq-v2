# frozen_string_literal: true

module Tokens
  # Background job to run AI analysis on a token after data is ready
  # Uses OpenAI GPT-4o with comprehensive prompts from v1
  class AnalyzeJob < ApplicationJob
    queue_as :default

    def perform(token_id)
      token = Token.find(token_id)

      # Run AI analysis with all collected data
      analysis_result = Analysis::TokenPairAnalysisService.new(
        token,
        {
          symbol: token.symbol,
          quote_symbol: token.quote_symbol
        }
      ).analyze

      # Cache analysis result (5 min TTL)
      cache_key = "pair_analysis:#{token.pool_address}:#{token.chain_id}"
      Rails.cache.write(cache_key, analysis_result, expires_in: 5.minutes)

      # Broadcast to extension via WebSocket
      TokenStatusChannel.broadcast_readiness(
        token,
        tier: 'rich',
        data: {
          has_dexscreener: token.dexscreener_snapshots.exists?,
          has_gecko_terminal: token.gecko_terminal_snapshots.exists?,
          has_ohlcv: token.gecko_ohlcv_snapshots.exists?,
          analysis_preview: analysis_result[:assistant]
        }
      )

      Rails.logger.info("AI analysis complete for token #{token.id}")
    rescue StandardError => e
      Rails.logger.error("AI analysis failed for token #{token_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      # Don't re-raise - we don't want to retry AI analysis on failure
    end
  end
end
