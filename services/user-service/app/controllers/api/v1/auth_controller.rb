class Api::V1::AuthController < Api::V1::BaseController
  
  def login
    # Input validation
    unless valid_login_params?
      return error_response('Invalid input parameters', [], :bad_request)
    end

    user = User.find_by(email: params[:email]&.downcase&.strip)
    
    if user&.valid_password?(params[:password])
      # Check if account is locked
      if user.access_locked?
        return error_response('Account is temporarily locked due to too many failed attempts', [], :locked)
      end
      
      if user.active?
        # Reset failed attempts on successful login
        user.update(failed_attempts: 0, locked_at: nil) if user.failed_attempts > 0
        
        user.update_last_login
        
        # Log successful login
        Rails.logger.info "Successful login for user #{user.email} from IP #{request.remote_ip}"
        
        success_response(
          {
            user: user_serializer(user),
            token: user.generate_jwt_token,
            refresh_token: user.generate_refresh_token
          },
          'Login successful'
        )
      else
        Rails.logger.warn "Login attempt for inactive account: #{params[:email]} from IP #{request.remote_ip}"
        error_response('Account is not active', [], :unauthorized)
      end
    else
      # Increment failed attempts
      if user
        user.increment!(:failed_attempts)
        
        # Lock account if max attempts reached
        if user.failed_attempts >= Devise.maximum_attempts
          user.update(locked_at: Time.current)
          Rails.logger.warn "Account locked for user #{user.email} from IP #{request.remote_ip}"
        end
      end
      
      Rails.logger.warn "Failed login attempt for email: #{params[:email]} from IP #{request.remote_ip}"
      error_response('Invalid email or password', [], :unauthorized)
    end
  rescue => e
    Rails.logger.error "Login error: #{e.message}"
    error_response('Internal server error', [], :internal_server_error)
  end
  
  def register
    # Input validation
    unless valid_registration_params?
      return error_response('Invalid input parameters', [], :bad_request)
    end

    user = User.new(user_params)
    
    if user.save
      # Log successful registration
      Rails.logger.info "Successful registration for user #{user.email} from IP #{request.remote_ip}"
      
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
      # Handle validation errors
      error_messages = user.errors.full_messages
      
      Rails.logger.warn "Failed registration attempt for email: #{params.dig(:user, :email)} from IP #{request.remote_ip}"
      error_response('Registration failed', error_messages, :unprocessable_entity)
    end
  rescue => e
    Rails.logger.error "Registration error: #{e.message}"
    error_response('Internal server error', [], :internal_server_error)
  end
  
  def refresh
    begin
      # Validate refresh token parameter
      unless params[:refresh_token].present?
        Rails.logger.warn "Refresh attempt without token from IP #{request.remote_ip}"
        return error_response('Refresh token is required', [], :bad_request)
      end

      # Get the JWT secret key
      begin
        secret_key = jwt_secret_key
        Rails.logger.info "JWT secret key obtained successfully, length: #{secret_key.length}" if Rails.env.development?
        Rails.logger.info "Using JWT secret key: #{secret_key[0..20]}..." if Rails.env.development?
      rescue => e
        Rails.logger.error "Failed to get JWT secret key: #{e.class} - #{e.message} from IP #{request.remote_ip}"
        return error_response('Internal server error', [], :internal_server_error)
      end

      # Decode the refresh token with detailed error handling
      begin
        Rails.logger.info "Attempting to decode JWT token from IP #{request.remote_ip}"
        decoded_token = JWT.decode(params[:refresh_token], secret_key, true, { algorithm: 'HS256' })
        Rails.logger.info "JWT decode successful, result type: #{decoded_token.class}, length: #{decoded_token&.length}"
        
        # Check if decoded_token is nil or empty
        unless decoded_token && decoded_token.is_a?(Array) && decoded_token.length > 0
          Rails.logger.error "JWT decode returned nil or invalid format from IP #{request.remote_ip}"
          return error_response('Invalid refresh token format', [], :unauthorized)
        end
        
        payload = decoded_token[0]
        Rails.logger.info "Payload extracted, type: #{payload.class}"
        
        # Check if payload is nil or not a hash
        unless payload && payload.is_a?(Hash)
          Rails.logger.error "JWT payload is nil or invalid format from IP #{request.remote_ip}"
          return error_response('Invalid refresh token format', [], :unauthorized)
        end
        
        Rails.logger.info "Refresh token decoded successfully for user_id: #{payload['user_id']} from IP #{request.remote_ip}"
      rescue JWT::DecodeError => e
        Rails.logger.error "JWT decode error: #{e.message}, token: #{params[:refresh_token][0..20]}... from IP #{request.remote_ip}"
        return error_response('Invalid refresh token format', [], :unauthorized)
      rescue JWT::ExpiredSignature => e
        Rails.logger.warn "Expired refresh token attempt from IP #{request.remote_ip}"
        return error_response('Refresh token expired', [], :unauthorized)
      rescue JWT::InvalidIssuerError => e
        Rails.logger.error "Invalid issuer in refresh token: #{e.message} from IP #{request.remote_ip}"
        return error_response('Invalid refresh token', [], :unauthorized)
      rescue JWT::InvalidAudError => e
        Rails.logger.error "Invalid audience in refresh token: #{e.message} from IP #{request.remote_ip}"
        return error_response('Invalid refresh token', [], :unauthorized)
      rescue => e
        Rails.logger.error "Unexpected JWT error: #{e.class} - #{e.message} from IP #{request.remote_ip}"
        return error_response('Invalid refresh token', [], :unauthorized)
      end

      # Validate payload structure
      unless payload['user_id'].present?
        Rails.logger.error "Refresh token missing user_id from IP #{request.remote_ip}"
        return error_response('Invalid refresh token', [], :unauthorized)
      end

      # Check if token is expired (additional check)
      if payload['exp'] && Time.at(payload['exp']) < Time.current
        Rails.logger.warn "Expired refresh token (manual check) from IP #{request.remote_ip}"
        return error_response('Refresh token expired', [], :unauthorized)
      end

      # Find user with detailed error handling
      begin
        user = User.find(payload['user_id'])
        Rails.logger.info "User found for refresh: #{user.email} (ID: #{user.id}) from IP #{request.remote_ip}"
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "User not found for refresh token: user_id=#{payload['user_id']} from IP #{request.remote_ip}"
        return error_response('Invalid refresh token', [], :unauthorized)
      end

      # Check if user is active
      unless user.active?
        Rails.logger.warn "Inactive user refresh attempt: #{user.email} from IP #{request.remote_ip}"
        return error_response('Account is not active', [], :unauthorized)
      end

      # Generate new tokens
      new_token = user.generate_jwt_token
      new_refresh_token = user.generate_refresh_token

      Rails.logger.info "Token refresh successful for user: #{user.email} from IP #{request.remote_ip}"
      
      success_response(
        {
          token: new_token,
          refresh_token: new_refresh_token
        },
        'Token refreshed successfully'
      )
    rescue => e
      Rails.logger.error "Unexpected error in token refresh: #{e.class} - #{e.message} from IP #{request.remote_ip}"
      error_response('Internal server error', [], :internal_server_error)
    end
  end
  
  def logout
    # In a real implementation, you might want to add the token to a denylist
    Rails.logger.info "User logout from IP #{request.remote_ip}"
    success_response({}, 'Logout successful')
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
  
  def jwt_secret_key
    secret_key = Rails.application.secret_key_base
    if secret_key.blank?
      Rails.logger.error "JWT secret key is blank or nil"
      raise "JWT secret key not configured"
    end
    secret_key
  end

  def valid_login_params?
    params[:email].present? && 
    params[:password].present? && 
    params[:email].is_a?(String) && 
    params[:password].is_a?(String) &&
    params[:email].length <= 255 &&
    params[:password].length <= 128
  end

  def valid_registration_params?
    user_data = params[:user]
    return false unless user_data.is_a?(ActionController::Parameters)
    
    user_data[:email].present? && 
    user_data[:password].present? && 
    user_data[:password_confirmation].present? &&
    user_data[:first_name].present? &&
    user_data[:last_name].present? &&
    user_data[:phone].present? &&
    user_data[:email].is_a?(String) &&
    user_data[:password].is_a?(String) &&
    user_data[:first_name].is_a?(String) &&
    user_data[:last_name].is_a?(String) &&
    user_data[:phone].is_a?(String) &&
    user_data[:email].length <= 255 &&
    user_data[:password].length <= 128 &&
    user_data[:first_name].length <= 50 &&
    user_data[:last_name].length <= 50 &&
    user_data[:phone].length <= 20
  end
end
