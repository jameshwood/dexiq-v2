source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.0.0'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Use devise for authentication
gem "devise"

# API authentication
gem "devise_token_auth"

# CORS support for API
gem "rack-cors"

# .env file support
gem "dotenv-rails"

# image storage
gem "cloudinary"

# transactional emails
gem "postmark-rails"

# payment processing
gem "pay", "~> 7.0"

# To use Stripe, also include:
gem "stripe", "~> 12.0"

# To use Braintree + PayPal, also include:
gem "braintree", "~> 4.7"

# To use Paddle Billing or Paddle Classic, also include:
gem "paddle", "~> 2.5"

# To use Lemon Squeezy, also include:
gem "lemonsqueezy", "~> 1.0"

# To use Receipts gem for creating invoice and receipt PDFs, also include:
gem "receipts", "~> 2.0"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# HTTP client for external APIs
gem "faraday"
gem "faraday-retry"

# Structured logging
gem "lograge"

# OpenAI integration
gem "ruby-openai"

# Background jobs
gem "sidekiq"

#database
gem "pg"

#open emails in development
gem "letter_opener"

# Use Tailwind CSS for styles [https://tailwindcss.com/docs/guides/rails]
gem "tailwindcss-rails"

# Admin interface
gem "motor-admin"

# Icons
gem "lucide-rails"

# Remove Metex_ warning
gem "mutex_m"

# Remove ostruct warning
gem "ostruct"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

end



