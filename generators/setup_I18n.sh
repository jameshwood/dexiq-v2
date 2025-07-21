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
  scope "/:locale" do
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

# Now update default_url_options since routes are scoped
sed -i '' 's/{ host: ENV\["DOMAIN"\] || "localhost:3000" }/{ host: ENV\["DOMAIN"\] || "localhost:3000", locale: I18n.locale }/' "$APP_CONTROLLER"
echo "✅ Updated default_url_options for scoped routes"

echo "🎉 I18n setup complete! You can now use multiple languages in your app."