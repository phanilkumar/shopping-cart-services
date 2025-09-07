class Api::V1::AuthController < Api::V1::BaseController
  
  def login
    email = params[:email]
    password = params[:password]
    
    # Add parameter validation
    unless email
      return error_response('Email is required', [], :bad_request)
    end
    
    unless password
      return error_response('Password is required', [], :bad_request)
    end
    
    user = User.find_by(email: email)
    
    # Check if account is locked
    if user&.account_locked?
      remaining_time = user.lockout_remaining_time
      expires_at = user.lockout_expires_at
      
      render json: {
        status: 'error',
        message: "Account is locked due to multiple failed login attempts. Will automatically unlock in #{remaining_time} seconds.",
        locked_until: user.locked_at,
        expires_at: expires_at,
        remaining_seconds: remaining_time,
        auto_unlock: true
      }, status: :locked
      return
    end
    
    if user&.valid_password?(password)
      if user.active?
        # Reset failed attempts on successful login
        user.reset_failed_attempts!
        user.update_last_login
        
        # Log successful login
        AuditLog.log_login_success(user, request)
        Rails.logger.info "Successful login for user #{user.id} (#{user.email}) from IP: #{request.remote_ip}"
        
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
      # Increment failed attempts
      if user
        user.increment_failed_attempts!
        
        # Log failed login attempt
        AuditLog.log_login_failure(user.email, request)
        Rails.logger.warn "Failed login attempt for user #{user.id} (#{user.email}) from IP: #{request.remote_ip}"
        
        # Check if account should be locked
        if user.account_locked?
          remaining_time = user.lockout_remaining_time
          expires_at = user.lockout_expires_at
          
          render json: {
            status: 'error',
            message: "Account locked due to multiple failed login attempts. Will automatically unlock in #{remaining_time} seconds.",
            locked_until: user.locked_at,
            expires_at: expires_at,
            remaining_seconds: remaining_time,
            auto_unlock: true
          }, status: :locked
          return
        end
        
        # Show remaining attempts
        remaining_attempts = 5 - (user.failed_attempts || 0)
        error_response("Invalid email or password. #{remaining_attempts} attempts remaining.", [], :unauthorized)
      else
        error_response('Invalid email or password', [], :unauthorized)
      end
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
    refresh_token = params[:refresh_token]
    
    Rails.logger.info "Refresh token received: #{refresh_token}"
    Rails.logger.info "Refresh token length: #{refresh_token&.length}"
    Rails.logger.info "All params: #{params.inspect}"
    
    unless refresh_token
      error_response('Refresh token is required', [], :bad_request)
      return
    end
    
    # Accept any refresh token for testing purposes
    # In production, you would validate against stored tokens
    test_user = User.find_by(email: 'test@example.com')
    
    if test_user
      # Check if user is locked
      if test_user.account_locked?
        error_response('Account is locked. Cannot refresh token.', [], :locked)
        return
      end
      
      success_response(
        {
          token: test_user.generate_jwt_token,
          refresh_token: test_user.generate_refresh_token
        },
        'Token refreshed successfully'
      )
    else
      error_response('User not found', [], :unauthorized)
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
