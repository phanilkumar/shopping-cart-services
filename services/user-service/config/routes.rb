Rails.application.routes.draw do
  # Health check route for Docker
  get '/health', to: 'application#health'
  
  # Devise routes
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }

  # Root route (must come after Devise routes)
  root to: 'pages#home'
  
  # Authentication routes (redirects to Devise)
  get '/login', to: 'users/sessions#new'
  get '/register', to: 'auth#register'
  post '/register', to: 'auth#create_register'
  delete '/logout', to: 'auth#logout'
  get '/logout', to: 'auth#logout'
  get '/congratulations', to: 'auth#congratulations'
  get '/dashboard', to: 'auth#dashboard'
  
  # Legal pages
  get '/terms', to: 'pages#terms_of_service'
  get '/privacy', to: 'pages#privacy_policy'
  get '/debug-language', to: 'pages#debug_language'
  
  # Language switching
  get '/languages', to: 'languages#index'
  get '/languages/:locale', to: 'languages#change', as: :change_language
  
  # Security routes
  get '/security', to: 'security#dashboard'
  get '/security/rate-limit-test', to: 'security#rate_limit_test'
  get '/security/status', to: 'security#security_status'
  post '/security/enable-2fa', to: 'security#enable_2fa'
  post '/security/disable-2fa', to: 'security#disable_2fa'
  post '/security/verify-otp', to: 'security#verify_otp'
  get '/security/qr-code', to: 'security#qr_code'
  post '/security/unlock-account/:user_id', to: 'security#unlock_account'
  post '/security/reset-failed-attempts/:user_id', to: 'security#reset_failed_attempts'

  # API routes (for React frontend)
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post '/auth/login', to: 'auth#login'
      post '/auth/register', to: 'auth#register'
      post '/auth/refresh', to: 'auth#refresh'
      post '/auth/otp/send', to: 'otp#send_otp'
      post '/auth/otp/verify', to: 'otp#verify_otp'
      delete '/auth/logout', to: 'auth#logout'
      
      # Security routes
      get '/security/status', to: 'security#security_status'
      post '/security/enable-2fa', to: 'security#enable_2fa'
      post '/security/disable-2fa', to: 'security#disable_2fa'
      post '/security/verify-otp', to: 'security#verify_otp'
      get '/security/qr-code', to: 'security#qr_code'
      post '/security/unlock-account/:user_id', to: 'security#unlock_account'
      post '/security/reset-failed-attempts/:user_id', to: 'security#reset_failed_attempts'
      
      # User management routes
      get '/users/profile', to: 'users#profile'
      put '/users/profile', to: 'users#update_profile'
      get '/users/:id', to: 'users#show'
      put '/users/:id', to: 'users#update'
      delete '/users/:id', to: 'users#destroy'
      
      # Audit logging routes (admin only)
      get '/audit-logs', to: 'audit_logs#index'
      get '/audit-logs/:id', to: 'audit_logs#show'
      get '/audit-logs/user/:user_id/activity', to: 'audit_logs#user_activity'
      get '/audit-logs/security/events', to: 'audit_logs#security_events'
      get '/audit-logs/login/events', to: 'audit_logs#login_events'
      get '/audit-logs/statistics', to: 'audit_logs#statistics'
    end
  end
end
