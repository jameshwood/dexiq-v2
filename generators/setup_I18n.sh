#!/bin/bash

set -e

echo "🌐 Setting up I18n support..."

# Define variables
APP_CONTROLLER="app/controllers/application_controller.rb"

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

# 4. Update routes.rb to add locale scoping
echo "🛣️  Updating routes with locale scoping..."

# Backup current routes
BACKUP_FILE="config/routes.rb.backup.$(date +%s)"
cp config/routes.rb "$BACKUP_FILE"

# Create new routes file
cat > config/routes.rb.new << 'EOL'
Rails.application.routes.draw do
  # Locale change route (outside scope)
  get '/locale/:locale', to: 'locale#change', as: :change_locale
  
  # Motor Admin (outside locale scope - admin interface)
  authenticate :user, lambda { |u| u.admin? } do
    mount Motor::Admin => '/motor_admin'
  end
  
  # Scope all routes under locale (except admin)
  scope "/:locale", locale: /#{I18n.available_locales.join("|")}/ do
EOL

# Extract existing routes properly
# Read the backup file and extract routes that should be scoped
while IFS= read -r line; do
  # Skip lines that should not be in the scope
  if [[ "$line" =~ ^[[:space:]]*get[[:space:]]+[\'\"]/locale/ ]]; then
    continue
  elif [[ "$line" =~ ^[[:space:]]*mount[[:space:]]+Motor::Admin ]]; then
    continue
  elif [[ "$line" =~ ^[[:space:]]*authenticate[[:space:]]+:user ]]; then
    continue
  elif [[ "$line" =~ ^[[:space:]]*end[[:space:]]*$ ]]; then
    continue
  elif [[ "$line" =~ ^[[:space:]]*scope ]]; then
    continue
  elif [[ "$line" =~ ^[[:space:]]*Rails\.application\.routes\.draw ]]; then
    continue
  elif [[ "$line" =~ ^[[:space:]]*end[[:space:]]*$ ]]; then
    continue
  else
    # Add proper indentation for scoped routes
    if [[ "$line" =~ ^[[:space:]]*[a-zA-Z] ]]; then
      echo "    $line" >> config/routes.rb.new
    else
      echo "$line" >> config/routes.rb.new
    fi
  fi
done < "$BACKUP_FILE"

# Add the closing parts
cat >> config/routes.rb.new << 'EOL'
  end

  # Default locale redirects
  get '*path', to: redirect("/#{I18n.default_locale}/%{path}"), constraints: lambda { |req| !req.path.start_with?("/#{I18n.default_locale}/") && !req.path.start_with?("/locale/") && !req.path.start_with?("/motor_admin") }
  get '', to: redirect("/#{I18n.default_locale}")
end
EOL

# Replace the routes file
mv config/routes.rb.new config/routes.rb

echo "✅ Updated routes with locale scoping"
echo ""
echo "🌐 Your routes are now scoped under locale:"
echo "   - English: /en/"
echo "   - Spanish: /es/"
echo "   - French: /fr/"
echo "   - German: /de/"
echo ""
echo "📝 Original routes backed up to: $BACKUP_FILE"
echo "🔄 To revert: cp $BACKUP_FILE config/routes.rb"
echo ""

# 5. Add render to layout if not present (fixed position)
LAYOUT="app/views/layouts/application.html.erb"
RENDER_LINE='<%= render "components/language_switcher" %>'

echo "🔍 Checking layout file: $LAYOUT"
if [[ -f "$LAYOUT" ]]; then
  echo "✅ Layout file exists"
  
  if ! grep -qF "$RENDER_LINE" "$LAYOUT"; then
    echo "➕ Adding language switcher to layout..."
    # Add the language switcher after the opening body tag
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS sed
      sed -i '' '/<body>/a\
    '"$RENDER_LINE"'
' "$LAYOUT"
    else
      # Linux sed
      sed -i '/<body>/a\'$'\n    '"$RENDER_LINE"'' "$LAYOUT"
    fi
    echo "✅ Added fixed position language switcher to layout"
  else
    echo "ℹ️  Language switcher already present in layout"
  fi
else
  echo "❌ Layout file not found: $LAYOUT"
  exit 1
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
if ! grep -qF "before_action :set_locale" "$APP_CONTROLLER"; then
  # Create a backup
  cp "$APP_CONTROLLER" "$APP_CONTROLLER.backup"
  
  # Add before_action :set_locale after authenticate_user!
  sed -i '' '/before_action :authenticate_user!/a\
  before_action :set_locale\
' "$APP_CONTROLLER"

  # Add private methods before the final 'end'
  sed -i '' '/^end$/i\
  private\
\
  def set_locale\
    I18n.locale = extract_locale || I18n.default_locale\
  end\
\
  def extract_locale\
    # Get locale from URL params first\
    locale = params[:locale]\
    return locale.to_sym if locale && I18n.available_locales.map(&:to_s).include?(locale.to_s)\
    \
    # Fall back to session\
    locale = session[:locale]\
    return locale.to_sym if locale && I18n.available_locales.map(&:to_s).include?(locale.to_s)\
    \
    # Fall back to Accept-Language header\
    locale = request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first\
    return locale.to_sym if locale && I18n.available_locales.map(&:to_s).include?(locale)\
    \
    # Default to nil, which will use I18n.default_locale\
    nil\
  end\
' "$APP_CONTROLLER"

  # Update default_url_options to include locale if it exists
  if grep -qF "def default_url_options" "$APP_CONTROLLER"; then
    sed -i '' 's/{ host: ENV\["DOMAIN"\] || "localhost:3000" }/{ host: ENV["DOMAIN"] || "localhost:3000", locale: I18n.locale }/' "$APP_CONTROLLER"
  else
    # Add default_url_options method before the private section
    sed -i '' '/private/i\
  def default_url_options\
    { host: ENV["DOMAIN"] || "localhost:3000", locale: I18n.locale }\
  end\
' "$APP_CONTROLLER"
  fi

  echo "✅ Added locale logic to ApplicationController"
  echo "📝 Original ApplicationController backed up to: $APP_CONTROLLER.backup"
else
  echo "ℹ️  Locale logic already present in ApplicationController"
fi

echo "🎉 I18n setup complete! You can now use multiple languages in your app."