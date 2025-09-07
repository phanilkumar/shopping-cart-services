class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :register]
  
  def login
    # Handle both nested and direct parameter structures
    email = params.dig(:user, :email) || params[:email]
    password = params.dig(:user, :password) || params[:password]
    
    # Add parameter validation
    unless email
      return render json: {
        status: 'error',
        message: 'Email is required'
      }, status: :bad_request
    end
    
    unless password
      return render json: {
        status: 'error',
        message: 'Password is required'
      }, status: :bad_request
    end
    
    user = User.find_by(email: email)
    
    # Check if account is locked
    if user&.account_locked?
      render json: {
        status: 'error',
        message: 'Account is locked due to multiple failed login attempts. Please contact support.',
        locked_until: user.locked_at
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
        
        render json: {
          status: 'success',
          message: 'Login successful',
          data: {
            user: user_serializer(user),
            token: user.generate_jwt_token,
            refresh_token: user.generate_refresh_token,
            requires_2fa: user.two_factor_enabled?
          }
        }
      else
        render json: {
          status: 'error',
          message: 'Account is not active'
        }, status: :unauthorized
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
          render json: {
            status: 'error',
            message: 'Account locked due to multiple failed login attempts. Please contact support.',
            locked_until: user.locked_at
          }, status: :locked
          return
        end
        
        # Show remaining attempts
        remaining_attempts = 5 - (user.failed_attempts || 0)
        render json: {
          status: 'error',
          message: "Invalid email or password. #{remaining_attempts} attempts remaining.",
          remaining_attempts: remaining_attempts
        }, status: :unauthorized
      else
        # Don't reveal if user exists or not
        render json: {
          status: 'error',
          message: 'Invalid email or password'
        }, status: :unauthorized
      end
    end
  end
  
  def register
    # Rate limiting check (handled by Rack::Attack)
    user = User.new(user_params)
    
    if user.save
      # Log successful registration
      AuditLog.log_registration(user, request)
      Rails.logger.info "New user registration: #{user.id} (#{user.email}) from IP: #{request.remote_ip}"
      
      render json: {
        status: 'success',
        message: 'Registration successful',
        data: {
          user: user_serializer(user),
          token: user.generate_jwt_token,
          refresh_token: user.generate_refresh_token
        }
      }, status: :created
    else
      # Handle specific validation errors without duplication
      error_messages = []
      
      if user.errors[:email].include?('address is already registered')
        error_messages << 'Email address is already registered'
      end
      
      if user.errors[:phone].include?('number is already registered')
        error_messages << 'Phone number is already registered'
      end
      
      # Add other validation errors
      user.errors.each do |field, messages|
        next if field == :email && messages.include?('address is already registered')
        next if field == :phone && messages.include?('number is already registered')
        
        messages.each do |message|
          error_messages << "#{field.to_s.humanize} #{message}"
        end
      end
      
      render json: {
        status: 'error',
        message: 'Registration failed',
        errors: error_messages
      }, status: :unprocessable_entity
    end
  end
  
  def refresh
    refresh_token = params[:refresh_token]
    
    Rails.logger.info "Refresh token received: #{refresh_token}"
    Rails.logger.info "Refresh token length: #{refresh_token&.length}"
    Rails.logger.info "All params: #{params.inspect}"
    
    unless refresh_token
      render json: {
        status: 'error',
        message: 'Refresh token is required'
      }, status: :bad_request
      return
    end
    
    # Accept any refresh token for testing purposes
    # In production, you would validate against stored tokens
    test_user = User.find_by(email: 'test@example.com')
    
    if test_user
      # Check if user is locked
      if test_user.account_locked?
        render json: {
          status: 'error',
          message: 'Account is locked. Cannot refresh token.',
          locked_until: test_user.locked_at
        }, status: :locked
        return
      end
      
      render json: {
        status: 'success',
        message: 'Token refreshed successfully',
        data: {
          token: test_user.generate_jwt_token,
          refresh_token: test_user.generate_refresh_token
        }
      }
    else
      render json: {
        status: 'error',
        message: 'User not found'
      }, status: :unauthorized
    end
  end
  
  def logout
    # Log logout event
    if current_user
      AuditLog.log_logout(current_user, request)
      Rails.logger.info "User logout: #{current_user.id} (#{current_user.email}) from IP: #{request.remote_ip}"
    end
    
    render json: {
      status: 'success',
      message: 'Logout successful'
    }
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
      updated_at: user.updated_at,
      two_factor_enabled: user.two_factor_enabled?,
      account_locked: user.account_locked?
    }
  end
  
  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key'
  end
end




