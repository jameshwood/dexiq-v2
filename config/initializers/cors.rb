# frozen_string_literal: true

# CORS configuration for API and Chrome extension
# Allows the extension to communicate with the Rails API

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Chrome extension origins (will be environment-specific)
    origins_list = ENV.fetch('EXTENSION_ALLOWED_ORIGINS', 'chrome-extension://').split(',')

    # In development, also allow localhost for testing
    if Rails.env.development?
      origins_list += ['http://localhost:3000', 'http://127.0.0.1:3000']
    end

    origins(*origins_list)

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['access-token', 'expiry', 'token-type', 'uid', 'client']
  end

  allow do
    # WebSocket connections for ActionCable
    origins_list = ENV.fetch('EXTENSION_ALLOWED_ORIGINS', 'chrome-extension://').split(',')

    if Rails.env.development?
      origins_list += ['http://localhost:3000', 'http://127.0.0.1:3000']
    end

    origins(*origins_list)

    resource '/cable',
      headers: :any,
      methods: [:get, :post, :options],
      credentials: true
  end
end
