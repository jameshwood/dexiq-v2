module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags 'ActionCable', "User #{current_user.id}"
    end

    private

    def find_verified_user
      # Try to authenticate via query string parameters
      # Extension will send auth token via: ws://...?token=XXX
      if verified_user = authenticate_from_token
        verified_user
      else
        reject_unauthorized_connection
      end
    end

    def authenticate_from_token
      # Get token from query params
      token = request.params[:token]
      return nil unless token.present?

      # TODO: Implement proper token verification
      # For now, we'll use a simple approach - in production, use JWT or signed tokens
      #
      # Option 1: JWT tokens
      # decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')
      # User.find_by(id: decoded[0]['user_id'])
      #
      # Option 2: Devise token auth (if using it)
      # Use devise_token_auth headers passed through query params
      #
      # For now, simple development approach:
      user_id = verify_token(token)
      User.find_by(id: user_id) if user_id
    rescue StandardError => e
      Rails.logger.error("ActionCable auth error: #{e.message}")
      nil
    end

    def verify_token(token)
      # TODO: Implement secure token verification
      # For development, this is a placeholder
      # In production, use JWT.decode or similar
      #
      # Example JWT verification:
      # payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')
      # payload[0]['user_id']
      nil # Placeholder - requires implementation
    end
  end
end
