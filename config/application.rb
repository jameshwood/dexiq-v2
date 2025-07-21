require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LightningRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.action_mailer.default_url_options = { host: "example.com" } # replace with your own domain
     config.action_mailer.delivery_method = :postmark
     config.action_mailer.postmark_settings = { :api_token => ENV['POSTMARK_API_TOKEN'] }
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
