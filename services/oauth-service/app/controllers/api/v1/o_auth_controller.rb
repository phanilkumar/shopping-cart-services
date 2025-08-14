class Api::V1::OAuthController < ApplicationController
  skip_before_action :authenticate_user!
  
  def google
    redirect_to_oauth_provider('google')
  end
  
  def facebook
    redirect_to_oauth_provider('facebook')
  end
  
  def github
    redirect_to_oauth_provider('github')
  end
  
  def twitter
    redirect_to_oauth_provider('twitter')
  end
  
  def linkedin
    redirect_to_oauth_provider('linkedin')
  end
  
  def callback
    provider = params[:provider] || detect_provider_from_url
    
    begin
      auth_data = process_oauth_callback(provider)
      user = find_or_create_user_from_oauth(auth_data)
      
      if user
        user.update_last_login
        render json: {
          status: 'success',
          message: "#{provider.titleize} authentication successful",
          data: {
            user: user_serializer(user),
            token: user.generate_jwt_token,
            refresh_token: user.generate_refresh_token,
            provider: provider
          }
        }
      else
        render json: {
          status: 'error',
          message: 'Failed to authenticate with OAuth provider'
        }, status: :unauthorized
      end
    rescue => e
      render json: {
        status: 'error',
        message: 'OAuth authentication failed',
        error: e.message
      }, status: :unauthorized
    end
  end
  
  private
  
  def redirect_to_oauth_provider(provider)
    # In a real implementation, you would redirect to the OAuth provider
    # For now, we'll return a mock response
    render json: {
      status: 'redirect',
      provider: provider,
      auth_url: "#{request.base_url}/oauth/#{provider}/authorize"
    }
  end
  
  def detect_provider_from_url
    # Extract provider from the callback URL
    request.path.split('/').last
  end
  
  def process_oauth_callback(provider)
    # In a real implementation, you would process the OAuth callback
    # and extract user information from the provider
    {
      provider: provider,
      provider_uid: "mock_uid_#{SecureRandom.hex(8)}",
      email: "user_#{SecureRandom.hex(4)}@example.com",
      first_name: "User",
      last_name: "Name",
      access_token: "mock_access_token_#{SecureRandom.hex(16)}",
      refresh_token: "mock_refresh_token_#{SecureRandom.hex(16)}",
      expires_at: 1.hour.from_now
    }
  end
  
  def find_or_create_user_from_oauth(auth_data)
    # First, try to find user by OAuth account
    oauth_account = OAuthAccount.find_by(
      provider: auth_data[:provider],
      provider_uid: auth_data[:provider_uid]
    )
    
    if oauth_account
      user = oauth_account.user
      oauth_account.update!(
        access_token: auth_data[:access_token],
        refresh_token: auth_data[:refresh_token],
        expires_at: auth_data[:expires_at]
      )
      return user
    end
    
    # If no OAuth account found, try to find user by email
    user = User.find_by(email: auth_data[:email])
    
    if user
      # User exists, create OAuth account
      OAuthAccount.create!(
        user: user,
        provider: auth_data[:provider],
        provider_uid: auth_data[:provider_uid],
        access_token: auth_data[:access_token],
        refresh_token: auth_data[:refresh_token],
        expires_at: auth_data[:expires_at]
      )
      return user
    else
      # Create new user with OAuth data
      user = User.create!(
        email: auth_data[:email],
        first_name: auth_data[:first_name],
        last_name: auth_data[:last_name],
        phone: '0000000000', # Default phone
        password: SecureRandom.hex(16), # Random password
        password_confirmation: SecureRandom.hex(16),
        status: :active
      )
      
      OAuthAccount.create!(
        user: user,
        provider: auth_data[:provider],
        provider_uid: auth_data[:provider_uid],
        access_token: auth_data[:access_token],
        refresh_token: auth_data[:refresh_token],
        expires_at: auth_data[:expires_at]
      )
      
      return user
    end
  end
  
  def user_serializer(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      phone: user.phone,
      status: user.status,
      role: user.role,
      last_login_at: user.last_login_at,
      connected_providers: user.connected_providers,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
