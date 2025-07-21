class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :set_locale

  private

  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
  end

  def extract_locale
    parsed_locale = params[:locale] || session[:locale] || request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first
    parsed_locale if I18n.available_locales.map(&:to_s).include?(parsed_locale)
  end

  # This method overrides Rails.application.default_url_options[:host] to add an absolute URL to meta tags, good for SEO
  def default_url_options
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end
end
