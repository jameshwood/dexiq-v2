# frozen_string_literal: true

# OpenAI configuration for AI analysis and chat

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_API_KEY', nil)
  config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID', nil) # Optional

  # TODO: Uncomment and configure if using Azure OpenAI
  # config.uri_base = ENV.fetch('OPENAI_API_BASE_URL', 'https://api.openai.com')

  config.request_timeout = 60 # Timeout in seconds

  # Log API calls in development
  if Rails.env.development?
    config.log_errors = true
  end
end

# Helper module for OpenAI operations
module OpenAIHelpers
  DEFAULT_MODEL = ENV.fetch('OPENAI_MODEL', 'gpt-4o').freeze
  DEFAULT_TEMPERATURE = 0.7
  DEFAULT_MAX_TOKENS = 2000

  def self.client
    @client ||= OpenAI::Client.new
  end

  def self.chat_completion(messages:, model: DEFAULT_MODEL, temperature: DEFAULT_TEMPERATURE, max_tokens: DEFAULT_MAX_TOKENS, **options)
    client.chat(
      parameters: {
        model: model,
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens
      }.merge(options)
    )
  rescue Faraday::Error => e
    Rails.logger.error("OpenAI API Error: #{e.class} - #{e.message}")
    raise
  end
end
