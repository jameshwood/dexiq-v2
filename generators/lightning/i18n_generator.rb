class Lightning::I18nGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  def create_locale_files
    copy_file 'config/locales/en.yml', 'config/locales/en.yml'
    copy_file 'config/locales/es.yml', 'config/locales/es.yml'
    copy_file 'config/locales/fr.yml', 'config/locales/fr.yml'
    copy_file 'config/locales/de.yml', 'config/locales/de.yml'
  end

  def create_locale_controller
    copy_file 'app/controllers/locale_controller.rb', 'app/controllers/locale_controller.rb'
  end

  def create_language_switcher_component
    copy_file 'app/views/components/_language_switcher.html.erb', 'app/views/components/_language_switcher.html.erb'
  end

  def update_routes
    route "get '/locale/:locale', to: 'locale#change', as: :change_locale"
  end

  def update_application_controller
    inject_into_file 'app/controllers/application_controller.rb', after: "class ApplicationController < ActionController::Base\n" do
      <<~RUBY
        before_action :set_locale

        private

        def set_locale
          I18n.locale = extract_locale || I18n.default_locale
        end

        def extract_locale
          parsed_locale = params[:locale] || session[:locale] || request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first
          parsed_locale if I18n.available_locales.map(&:to_s).include?(parsed_locale)
        end

        def default_url_options
          { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
        end
      RUBY
    end
  end

  def update_application_layout
    inject_into_file 'app/views/layouts/application.html.erb', after: '<%= render "shared/navbar" %>' do
      <<~ERB
        <%= render "components/language_switcher" %>
      ERB
    end
  end

  def update_config_application
    inject_into_file 'config/application.rb', after: "class Application < Rails::Application\n" do
      <<~RUBY
        # Configure available locales
        config.i18n.available_locales = [:en, :es, :fr, :de]
        config.i18n.default_locale = :en
        config.i18n.fallbacks = true
      RUBY
    end
  end

  def copy_devise_locale_files
    # Copy Devise locale files for additional languages
    copy_file 'config/locales/devise.en.yml', 'config/locales/devise.en.yml'
    copy_file 'config/locales/devise.es.yml', 'config/locales/devise.es.yml'
    copy_file 'config/locales/devise.fr.yml', 'config/locales/devise.fr.yml'
    copy_file 'config/locales/devise.de.yml', 'config/locales/devise.de.yml'
  end
end 