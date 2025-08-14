Rails.application.routes.draw do
  # Health check endpoint
  get '/health', to: 'health#check'
  
  # API versioning
  namespace :api do
    namespace :v1 do
      # OAuth routes
      get '/oauth/google', to: 'o_auth#google'
      get '/oauth/facebook', to: 'o_auth#facebook'
      get '/oauth/github', to: 'o_auth#github'
      get '/oauth/twitter', to: 'o_auth#twitter'
      get '/oauth/linkedin', to: 'o_auth#linkedin'
      get '/oauth/callback', to: 'o_auth#callback'
      
      # User routes
      resources :users, only: [:show, :update] do
        member do
          get :profile
        end
      end
    end
  end
  
  # Catch all route for unmatched API requests
  match '*path', to: 'application#not_found', via: :all
end
