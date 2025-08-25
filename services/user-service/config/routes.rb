Rails.application.routes.draw do
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
  
  # API routes (for React frontend)
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post '/auth/login', to: 'auth#login'
      post '/auth/otp/send', to: 'otp#send_otp'
      post '/auth/otp/verify', to: 'otp#verify_otp'
      delete '/auth/logout', to: 'auth#logout'
      
      # User management routes
      get '/users/profile', to: 'users#profile'
      put '/users/profile', to: 'users#update_profile'
      get '/users/:id', to: 'users#show'
      put '/users/:id', to: 'users#update'
      delete '/users/:id', to: 'users#destroy'
    end
  end
end
