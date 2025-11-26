# frozen_string_literal: true

# TokenStatusChannel streams real-time updates about token data readiness
# Extension subscribes to "token_status_#{token_id}" to receive notifications
# when external data has been fetched and analysis is available
class TokenStatusChannel < ApplicationCable::Channel
  def subscribed
    # Validate token_id parameter
    token_id = params[:token_id]

    unless token_id.present?
      reject
      return
    end

    # Verify user has access to this token
    token = current_user.tokens.find_by(id: token_id)

    unless token
      reject
      return
    end

    # Subscribe to token-specific stream
    stream_for token

    Rails.logger.info("TokenStatusChannel: User #{current_user.id} subscribed to token #{token_id}")
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    Rails.logger.info("TokenStatusChannel: User #{current_user.id} unsubscribed")
    stop_all_streams
  end

  # Class method to broadcast updates
  def self.broadcast_readiness(token, tier:, data: {})
    broadcast_to(token, {
      status: 'ready',
      tier: tier,
      token_id: token.id,
      timestamp: Time.current.iso8601,
      data: data
    })
  end

  def self.broadcast_error(token, error:)
    broadcast_to(token, {
      status: 'error',
      token_id: token.id,
      error: error,
      timestamp: Time.current.iso8601
    })
  end
end
