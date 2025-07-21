class LocaleController < ApplicationController
  skip_before_action :authenticate_user!
  
  def change
    locale = params[:locale].to_s.strip.to_sym
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      # Handle both scoped and non-scoped routes
      begin
        redirect_back(fallback_location: root_path(locale: locale))
      rescue ActionController::UrlGenerationError
        redirect_back(fallback_location: root_path)
      end
    else
      redirect_back(fallback_location: root_path)
    end
  end
end 