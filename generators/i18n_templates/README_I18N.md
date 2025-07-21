# 🌐 Internationalization (I18n) Setup

This document explains the I18n setup and how to use it effectively.

## Features

### ✅ What's Included

1. **Multi-language Support**: English, Spanish, French, German
2. **Devise Integration**: Complete Devise translations for all languages
3. **Fixed Position Language Switcher**: Always accessible in bottom-right corner
4. **URL-based Locale Switching**: Clean URLs with locale prefixes
5. **Comprehensive Translations**: Common UI elements, navigation, forms, errors
6. **Safe Route Backup**: Automatic backup of existing routes

### 🎨 Language Switcher

The language switcher is positioned as a **fixed floating button** in the bottom-right corner of the screen:

- **Location**: Fixed position, always visible
- **Style**: DaisyUI primary button with shadow effects
- **Accessibility**: Available on all pages without authentication
- **Animation**: Smooth hover transitions

### 🔧 Technical Implementation

#### LocaleController
```ruby
class LocaleController < ApplicationController
  skip_before_action :authenticate_user!  # No auth required
  
  def change
    locale = params[:locale].to_s.strip.to_sym
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      redirect_back(fallback_location: root_path)
    else
      redirect_back(fallback_location: root_path)
    end
  end
end
```

#### ApplicationController Integration
```ruby
class ApplicationController < ActionController::Base
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
end
```

## 🌐 URL-based Locale Switching

The setup automatically implements URL-based locale switching with clean URLs:

### Option 1: Manual Route Scoping

Update your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # Locale change route (outside scope)
  get '/locale/:locale', to: 'locale#change', as: :change_locale
  
  # Scope all routes under locale
  scope "/:locale" do
    authenticate :user, lambda { |u| u.admin? } do
      mount Motor::Admin => '/motor_admin'
    end
    devise_for :users
    get 'checkout', to: 'checkouts#show'
    get 'checkout/success', to: 'checkouts#success'
    root to: 'pages#home'
    get 'terms-and-conditions', to: 'pages#terms'
    get 'privacy-policy', to: 'pages#privacy'
    get 'cookies', to: 'pages#cookies'
  end
  
  # Default locale redirect
  get '*path', to: redirect("/#{I18n.default_locale}/%{path}"), constraints: lambda { |req| !req.path.start_with?("/#{I18n.default_locale}/") }
  get '', to: redirect("/#{I18n.default_locale}")
end
```

### URL Structure

The setup automatically creates clean, locale-prefixed URLs:
- **English**: `yoursite.com/en/` (default)
- **Spanish**: `yoursite.com/es/`
- **French**: `yoursite.com/fr/`
- **German**: `yoursite.com/de/`
- **Language switching**: `yoursite.com/locale/fr` (redirects to `/fr/`)

### Automatic Redirects
- `yoursite.com/` → `yoursite.com/en/`
- `yoursite.com/pages` → `yoursite.com/en/pages`
- `yoursite.com/locale/fr` → `yoursite.com/fr/`

## 📝 Using Translations

### In Views
```erb
<!-- Basic translation -->
<h1><%= t('pages.home.title') %></h1>

<!-- With interpolation -->
<p><%= t('welcome_message', name: @user.name) %></p>

<!-- Pluralization -->
<p><%= t('items', count: @items.count) %></p>
```

### In Controllers
```ruby
# Set flash messages
flash[:notice] = t('users.updated_successfully')

# Redirect with translation
redirect_to root_path, notice: t('users.welcome_back')
```

### In Models
```ruby
# Validation messages
validates :name, presence: { message: :blank }
```

## 🎨 Customizing the Language Switcher

### Position
The switcher is positioned with:
```css
.fixed.bottom-4.right-4.z-50
```

### Styling
- **Button**: `btn-circle btn-primary shadow-lg`
- **Dropdown**: `shadow-2xl bg-base-100 rounded-box`
- **Hover**: `hover:shadow-xl transition-shadow duration-200`

### Customization
Edit `app/views/components/_language_switcher.html.erb` to:
- Change position (e.g., `top-4` instead of `bottom-4`)
- Modify styling (e.g., different button colors)
- Add animations
- Change icon

## 🌍 Adding New Languages

1. **Create locale file**:
   ```bash
   cp config/locales/en.yml config/locales/it.yml
   ```

2. **Create Devise locale file**:
   ```bash
   cp config/locales/devise.en.yml config/locales/devise.it.yml
   ```

3. **Update configuration** in `config/application.rb`:
   ```ruby
   config.i18n.available_locales = [:en, :es, :fr, :de, :it]
   ```

4. **Add translations** to the new locale files

## 🔧 Troubleshooting

### Language switcher not showing
- Check that the component is rendered in `app/views/layouts/application.html.erb`
- Verify the component file exists at `app/views/components/_language_switcher.html.erb`

### Translations not working
- Ensure locale files are in `config/locales/`
- Check that the locale is in `config.i18n.available_locales`
- Verify the translation key exists in the locale file

### Routes not working
- Check that the locale change route is properly added
- Ensure `LocaleController` exists and has `skip_before_action :authenticate_user!`

## 📚 Best Practices

1. **Use translation keys consistently**
2. **Group related translations** (e.g., `pages.home.title`, `pages.about.title`)
3. **Use interpolation for dynamic content**
4. **Test all languages** after adding new translations
5. **Keep translations organized** in logical sections

## 🚀 Advanced Features

### RTL Support
For right-to-left languages, add CSS classes:
```erb
<html dir="<%= I18n.locale == :ar ? 'rtl' : 'ltr' %>">
```

### Number/Date Formatting
```ruby
# In locale files
number:
  currency:
    format:
      unit: "$"
      precision: 2
      separator: "."
      delimiter: ","

# In views
<%= number_to_currency(@price) %>
<%= l(@date, format: :long) %>
```

This setup provides a solid foundation for internationalization while keeping the boilerplate clean and simple! 