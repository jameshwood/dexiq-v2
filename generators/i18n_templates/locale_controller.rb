class LocaleController < ApplicationController
  skip_before_action :authenticate_user!
  
  def change
    locale = params[:locale].to_s.strip.to_sym
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      # Redirect to the same page but with the new locale
      redirect_to url_for(locale: locale)
    else
      redirect_back(fallback_location: root_path)
    end
  end
end 