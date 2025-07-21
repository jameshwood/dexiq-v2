class LocaleController < ApplicationController
  skip_before_action :authenticate_user!
  
  def change
    locale = params[:locale].to_s.strip.to_sym
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      redirect_back(fallback_location: root_path(locale: locale))
    else
      redirect_back(fallback_location: root_path(locale: I18n.default_locale))
    end
  end
end 