# frozen_string_literal: true

module Api
  module V1
    # Base controller for API v1
    # Provides common authentication and response helpers
    class BaseController < ActionController::API
      # TODO: Add authentication
      # For Devise Token Auth:
      # include DeviseTokenAuth::Concerns::SetUserByToken
      # before_action :authenticate_user!

      # For now, simple authentication (replace with proper auth)
      before_action :authenticate_api_user!

      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
      rescue_from ActionController::ParameterMissing, with: :parameter_missing

      private

      def authenticate_api_user!
        # TODO: Implement proper API authentication
        # Options:
        # 1. Devise Token Auth headers
        # 2. JWT tokens
        # 3. API keys
        #
        # For development, you can temporarily skip this or use a simple token
        # In production, this MUST be properly implemented

        # Placeholder implementation:
        @current_user ||= User.first # FIXME: Implement real authentication
      end

      attr_reader :current_user

      def render_success(data = {}, status: :ok)
        render json: { status: 'ok' }.merge(data), status: status
      end

      def render_error(message, status: :unprocessable_entity, errors: nil)
        response = { status: 'error', message: message }
        response[:errors] = errors if errors.present?
        render json: response, status: status
      end

      def record_not_found(exception)
        render_error("Resource not found: #{exception.message}", status: :not_found)
      end

      def record_invalid(exception)
        render_error(
          "Validation failed",
          errors: exception.record.errors.full_messages,
          status: :unprocessable_entity
        )
      end

      def parameter_missing(exception)
        render_error("Missing required parameter: #{exception.param}", status: :bad_request)
      end
    end
  end
end
