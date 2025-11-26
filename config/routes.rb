Rails.application.routes.draw do
  # Admin interface
  authenticate :user, lambda { |u| u.admin? } do
    mount Motor::Admin => '/motor_admin'
  end

  # Devise authentication
  devise_for :users

  # DexIQ API v1
  namespace :api do
    namespace :v1 do
      # Token endpoints
      resources :tokens, only: [:create, :show] do
        member do
          get 'status'
          post 'analyse_pair'
          get 'purchases'
          post 'purchases', action: :create_purchase
          post 'chat_with_ai'
        end
      end

      # Token list analysis (no token_id required)
      post 'analyse_tokens', to: 'tokens#analyse_tokens'
    end
  end

  # Landing page
  root to: 'landing#index'

  # Legacy routes (keep for backward compatibility)
  get 'checkout', to: 'checkouts#show'
  get 'checkout/success', to: 'checkouts#success'
  get 'terms-and-conditions', to: 'pages#terms'
  get 'privacy-policy', to: 'pages#privacy'
  get 'cookies', to: 'pages#cookies'
end
