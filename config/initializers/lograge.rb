# frozen_string_literal: true

# Lograge configuration for structured logging
# Outputs logs in JSON format for easier parsing

Rails.application.configure do
  config.lograge.enabled = true

  # Use JSON formatter
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Custom fields to add to each log line
  config.lograge.custom_options = lambda do |event|
    {
      time: Time.current.iso8601,
      pid: Process.pid,
      user_id: event.payload[:user_id],
      ip: event.payload[:ip],
      request_id: event.payload[:headers]['X-Request-ID']
    }.compact
  end

  # Log additional fields
  config.lograge.custom_payload do |controller|
    {
      user_id: controller.try(:current_user)&.id,
      ip: controller.request.remote_ip
    }
  end

  # Include request parameters (be careful with sensitive data)
  config.lograge.keep_original_rails_log = false
  config.lograge.logger = ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log"))
end
