class Api::V1::AuthController < Api::V1::BaseController
  
  def login
    user = User.find_by(email: params[:email])
    
    if user&.valid_password?(params[:password])
      if user.active?
        user.update_last_login
        success_response(
          {
            user: user_serializer(user),
            token: user.generate_jwt_token,
            refresh_token: user.generate_refresh_token
          },
          'Login successful'
        )
      else
        error_response('Account is not active', [], :unauthorized)
      end
    else
      error_response('Invalid email or password', [], :unauthorized)
    end
  end
  
  def register
    user = User.new(user_params)
    
    if user.save
      success_response(
        {
          user: user_serializer(user),
          token: user.generate_jwt_token,
          refresh_token: user.generate_refresh_token
        },
        'Registration successful',
        :created
      )
    else
      # Use the overridden errors.full_messages method
      error_messages = user.errors.full_messages
      error_response('Registration failed', error_messages, :unprocessable_entity)
    end
  end
  
  def refresh
    begin
      decoded_token = JWT.decode(params[:refresh_token], jwt_secret_key, true, { algorithm: 'HS256' })
      user_id = decoded_token[0]['user_id']
      user = User.find(user_id)
      
      success_response(
        {
          token: user.generate_jwt_token,
          refresh_token: user.generate_refresh_token
        },
        'Token refreshed successfully'
      )
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      error_response('Invalid refresh token', [], :unauthorized)
    end
  end
  
  def logout
    # In a real implementation, you might want to add the token to a denylist
    success_response({}, 'Logout successful')
  end
  
  def password_login
    identifier = params[:identifier]
    password = params[:password]
    
    # Determine if identifier is email or phone
    if identifier.include?('@')
      # Email authentication
      user = User.find_by(email: identifier.downcase)
      
      if user&.authenticate(password)
        if user.active?
          user.update_last_login
          success_response(
            {
              user: user_serializer(user),
              token: user.generate_jwt_token,
              refresh_token: user.generate_refresh_token
            },
            'Login successful'
          )
        else
          error_response('Account is not active', [], :unauthorized)
        end
      else
        error_response('Incorrect password. Please try again.', [], :unauthorized)
      end
    else
      error_response('Invalid authentication method', [], :bad_request)
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone)
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
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
  
end
