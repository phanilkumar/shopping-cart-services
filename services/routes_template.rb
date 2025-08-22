# frozen_string_literal: true

# Standardized Routes Template for all microservices
# This provides consistent API routing patterns across all services

Rails.application.routes.draw do
  # API routes with versioning
  namespace :api do
    namespace :v1 do
      # Health check endpoint (required for all services)
      get '/health', to: 'health#check'
      
      # Authentication routes (if applicable)
      post '/auth/login', to: 'auth#login'
      post '/auth/register', to: 'auth#register'
      post '/auth/refresh', to: 'auth#refresh'
      delete '/auth/logout', to: 'auth#logout'
      
      # OTP routes (if applicable)
      post '/auth/send-otp', to: 'otp#send_otp'
      post '/auth/verify-otp', to: 'otp#verify_otp'
      post '/auth/login-with-otp', to: 'otp#login_with_otp'
      
      # Password management routes (if applicable)
      post '/password/forgot', to: 'password#forgot'
      post '/password/reset', to: 'password#reset'
      
      # User routes (if applicable)
      get '/users/me', to: 'users#me'
      put '/users/me', to: 'users#update'
      put '/users/me/password', to: 'users#change_password'
      
      # Admin routes (if applicable)
      namespace :admin do
        resources :users, only: [:index, :show, :create, :update, :destroy] do
          member do
            patch :activate
            patch :deactivate
            patch :suspend
          end
        end
      end
      
      # Service-specific routes (override in each service)
      # Example for Product Service:
      # resources :products, only: [:index, :show, :create, :update, :destroy] do
      #   member do
      #     patch :activate
      #     patch :deactivate
      #     post :reviews
      #   end
      #   collection do
      #     get :search
      #     get :categories
      #   end
      # end
      
      # Example for Order Service:
      # resources :orders, only: [:index, :show, :create, :update] do
      #   member do
      #     patch :cancel
      #     patch :ship
      #     patch :deliver
      #     post :payments
      #   end
      #   collection do
      #     get :my_orders
      #     get :pending
      #     get :completed
      #   end
      # end
      
      # Example for Cart Service:
      # resources :cart_items, only: [:index, :create, :update, :destroy] do
      #   collection do
      #     delete :clear
      #     post :move_to_wishlist
      #   end
      # end
      
      # Example for Wallet Service:
      # resources :transactions, only: [:index, :show, :create] do
      #   collection do
      #     get :balance
      #     post :deposit
      #     post :withdraw
      #     post :transfer
      #   end
      # end
      
      # Example for Notification Service:
      # resources :notifications, only: [:index, :show, :update] do
      #   collection do
      #     patch :mark_all_read
      #     delete :clear_all
      #   end
      # end
    end
  end
  
  # Webhook routes (if applicable)
  namespace :webhooks do
    # Example webhook routes:
    # post '/stripe', to: 'stripe#handle'
    # post '/twilio', to: 'twilio#handle'
    # post '/sendgrid', to: 'sendgrid#handle'
  end
  
  # Admin panel routes (if applicable)
  namespace :admin do
    # Example admin panel routes:
    # get '/dashboard', to: 'dashboard#index'
    # resources :settings, only: [:index, :update]
  end
  
  # Health check for load balancers
  get '/health', to: 'health#check'
  
  # Root route (redirect to API documentation or health check)
  root to: 'health#check'
  
  # Catch-all route for undefined endpoints
  match '*path', to: 'application#not_found', via: :all
end
