Rails.application.routes.draw do
  # Hotwire routes (for web interface)
  root 'auth#login'
  
  # Authentication routes
  get '/login', to: 'auth#login'
  post '/login', to: 'auth#create_login'
  get '/register', to: 'auth#register'
  post '/register', to: 'auth#create_register'
  delete '/logout', to: 'auth#logout'
  get '/dashboard', to: 'auth#dashboard'
  
  # Legal pages
  get '/terms', to: 'pages#terms_of_service'
  get '/privacy', to: 'pages#privacy_policy'
  
  # API routes (for React frontend)
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post '/auth/login', to: 'auth#login'
      post '/auth/register', to: 'auth#register'
      post '/auth/password-login', to: 'auth#password_login'
      post '/auth/refresh', to: 'auth#refresh'
      delete '/auth/logout', to: 'auth#logout'
      
      # OTP routes
      post '/auth/send-otp', to: 'otp#send_otp'
      post '/auth/verify-otp', to: 'otp#verify_otp'
      post '/auth/login-with-otp', to: 'otp#login_with_otp'
      
      # Email validation route
      post '/auth/validate-email', to: 'otp#validate_email'
      
      # User routes
      get '/users/me', to: 'users#me'
      put '/users/me', to: 'users#update'
      put '/users/me/password', to: 'users#change_password'
      
      # Admin routes
      get '/admin/users', to: 'admin/users#index'
      post '/admin/users', to: 'admin/users#create'
      get '/admin/users/:id', to: 'admin/users#show'
      put '/admin/users/:id', to: 'admin/users#update'
      delete '/admin/users/:id', to: 'admin/users#destroy'
      patch '/admin/users/:id/activate', to: 'admin/users#activate'
      patch '/admin/users/:id/deactivate', to: 'admin/users#deactivate'
      patch '/admin/users/:id/suspend', to: 'admin/users#suspend'
      
      # Password management
      post '/password/forgot', to: 'password#forgot'
      post '/password/reset', to: 'password#reset'
      
      # Health check
      get '/health', to: 'health#check'
    end
  end
  
  # Catch-all route for 404 errors
  match '*path', to: 'application#not_found', via: :all
end
