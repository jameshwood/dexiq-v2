#!/bin/bash

set -e

echo "🌐 Setting up I18n support..."

# 1. Copy locale files
mkdir -p config/locales
cp generators/i18n_templates/en.yml config/locales/en.yml
cp generators/i18n_templates/es.yml config/locales/es.yml
cp generators/i18n_templates/fr.yml config/locales/fr.yml
cp generators/i18n_templates/de.yml config/locales/de.yml
cp generators/i18n_templates/devise.en.yml config/locales/devise.en.yml
cp generators/i18n_templates/devise.es.yml config/locales/devise.es.yml
cp generators/i18n_templates/devise.fr.yml config/locales/devise.fr.yml
cp generators/i18n_templates/devise.de.yml config/locales/devise.de.yml

# 2. Copy LocaleController
mkdir -p app/controllers
cp generators/i18n_templates/locale_controller.rb app/controllers/locale_controller.rb

# 3. Copy language switcher component
mkdir -p app/views/components
cp generators/i18n_templates/_language_switcher.html.erb app/views/components/_language_switcher.html.erb

# 4. Add route if not present
ROUTE="get '/locale/:locale', to: 'locale#change', as: :change_locale"
if ! grep -qF "$ROUTE" config/routes.rb; then
  # Add the route before the 'end' of the routes block
  sed -i '' '/^end$/i\
  '"$ROUTE"'
' config/routes.rb
  echo "✅ Added locale route to config/routes.rb"
fi

# 5. Add render to layout if not present
LAYOUT="app/views/layouts/application.html.erb"
RENDER_LINE='<%= render "components/language_switcher" %>'
if ! grep -qF "$RENDER_LINE" "$LAYOUT"; then
  # Add after navbar if possible, else append to file
  if grep -qF '<%= render "shared/navbar" %>' "$LAYOUT"; then
    sed -i '' '/<%= render "shared\/navbar" %>/a\
'"$RENDER_LINE"'
' "$LAYOUT"
  else
    echo "$RENDER_LINE" >> "$LAYOUT"
  fi
  echo "✅ Added language switcher to layout"
fi

# 6. Add I18n config to config/application.rb if not present
APP_CONFIG="config/application.rb"
I18N_CONFIG="config.i18n.available_locales = [:en, :es, :fr, :de]"
if ! grep -qF "$I18N_CONFIG" "$APP_CONFIG"; then
  sed -i '' '/class Application < Rails::Application/a\
    # Configure available locales\
    config.i18n.available_locales = [:en, :es, :fr, :de]\
    config.i18n.default_locale = :en\
    config.i18n.fallbacks = true\
' "$APP_CONFIG"
  echo "✅ Added I18n config to config/application.rb"
fi

# 7. Add locale logic to ApplicationController if not present
APP_CONTROLLER="app/controllers/application_controller.rb"
if ! grep -qF "before_action :set_locale" "$APP_CONTROLLER"; then
  sed -i '' '/class ApplicationController < ActionController::Base/a\
  before_action :set_locale\
\
  private\
\
  def set_locale\
    I18n.locale = extract_locale || I18n.default_locale\
  end\
\
  def extract_locale\
    parsed_locale = params[:locale] || session[:locale] || request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first\
    parsed_locale if I18n.available_locales.map(&:to_s).include?(parsed_locale)\
  end\
\
  def default_url_options\
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }\
  end\
' "$APP_CONTROLLER"
  echo "✅ Added locale logic to ApplicationController"
fi

echo "🎉 I18n setup complete! You can now use multiple languages in your app."
