#!/bin/bash

echo "🚀 Setting up your LightningRails project..."

# Step 1: Remove and change the Git remote
echo "🧼 Removing the source code's remote origin..."
git remote remove origin

echo "🛫 Creating a new GitHub repository..."
read -p "❓ Do you want to create a new private GitHub repository for this project? (y/n): " create_repo
if [[ "$create_repo" == "y" ]]; then
    read -p "🔑 Enter the name for your new repository: " repo_name
    gh repo create "$repo_name" --private --source=.
    echo "🎉 Repository '$repo_name' created successfully."
else
    echo "🤷‍♂️ Skipping GitHub repository creation."
fi

# Step 2: Collect company information
echo "🤝 Please provide your company details."

# Company name
read -p "🏢 What is your company name? (e.g. 'Lightning Rails') " company_name

# Company website
read -p "🌐 What is your company's website URL? (e.g. 'https://lightningrails.com') " company_website

# Write to meta.yml
cat <<EOL > config/meta.yml
meta_product_name: "$repo_name"
meta_title: "$repo_name"
meta_description: "$repo_name is the best product in the market"
meta_image: "cover.png"
twitter_account: "@product_twitter_account"
company_name: "$company_name"
company_website: "$company_website"
company_twitter: "$company_twitter"
setup_date: "$(date)"

# Theme
LIGHT_THEME: "light"
DARK_THEME: "dark"
EOL

echo "🎉 meta.yml has been updated with your company information. You should have basic information in the legal pages and meta SEO data. But don't hesitate to edit it."

# Step 4: Install dependencies
echo "🔍 Installing dependencies..."
bundle install

# Step 5: Set up the database
echo "💾 Setting up the database..."
rails db:drop db:create db:migrate

# Step 6: Reset the credentials file
echo "🔑 Resetting the credentials file..."
rm -rf config/credentials.yml.enc

# Step 7: Create and edit the .env file
echo "Creating the .env file..."
cp env.sample .env

# Stage all changes
git add .

# Create the initial commit
git commit -m "Initial commit: Set up company information in meta.yml"

# Push the changes to the remote repository
git push -u origin master


echo "Would you like to add internationalization (I18n) support? (y/n)"
read -r add_i18n

if [[ $add_i18n =~ ^[Yy]$ ]]; then
  echo "Adding I18n support..."
  bash generators/setup_I18n.sh
  echo "✅ I18n support added!"
  echo "📝 Note: Devise translations are included for English, Spanish, French, and German"
  echo "🌐 You can customize translations in config/locales/"
fi

echo "Setup complete! Your LightningRails project is ready to go 🚀. Happy Building!"
