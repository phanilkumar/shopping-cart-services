Rails.application.routes.draw do
  # Health check endpoint
  get '/health', to: 'health#check'
  
  # API versioning
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post '/auth/login', to: 'auth#login'
      post '/auth/register', to: 'auth#register'
      post '/auth/refresh', to: 'auth#refresh'
      delete '/auth/logout', to: 'auth#logout'
      
      # User routes
      resources :users, only: [:show, :update] do
        member do
          get :profile
        end
      end
      
      # Password management
      post '/password/forgot', to: 'passwords#forgot'
      post '/password/reset', to: 'passwords#reset'
      put '/password/change', to: 'passwords#change'
    end
  end
  
  # Catch all route for unmatched API requests
  match '*path', to: 'application#not_found', via: :all
end
