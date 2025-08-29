class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :register]
  
  def login
    # Rate limiting for login attempts
    rate_limit_key = "login_attempts_#{request.remote_ip}"
    attempts = Rails.cache.read(rate_limit_key) || 0
    
    if attempts >= 5
      return render json: {
        status: 'error',
        message: 'Too many login attempts. Please try again in 15 minutes.'
      }, status: :too_many_requests
    end
    
    user = User.find_by(email: params[:email])
    
    # Check if account is locked
    if user&.access_locked?
      return render json: {
        status: 'error',
        message: "Account temporarily locked due to multiple failed attempts. Please try again in #{((user.lock_expires_at - Time.current) / 60).ceil} minutes."
      }, status: :locked
    end
    
    if user&.valid_password?(params[:password])
      # Reset rate limit and failed attempts on successful login
      Rails.cache.delete(rate_limit_key)
      user.reset_failed_attempts!
      
      if user.active?
        user.update_last_login
        render json: {
          status: 'success',
          message: 'Login successful',
          data: {
            user: user_serializer(user),
            token: user.generate_jwt_token,
            refresh_token: user.generate_refresh_token
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
      Rails.cache.write(rate_limit_key, attempts + 1, expires_in: 15.minutes)
      
      if user
        user.increment_failed_attempts!
        
        if user.access_locked?
          return render json: {
            status: 'error',
            message: 'Account locked due to multiple failed attempts. Please try again in 15 minutes.'
          }, status: :locked
        end
      end
      
      render json: {
        status: 'error',
        message: 'Invalid email or password'
      }, status: :unauthorized
    end
  end
  
  def register
    user = User.new(user_params)
    
    if user.save
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
    begin
      decoded_token = JWT.decode(
        params[:refresh_token], 
        JWT_SECRET_KEY, 
        true, 
        { 
          algorithm: JWT_ALGORITHM,
          iss: JWT_ISSUER,
          aud: JWT_AUDIENCE,
          verify_iss: true,
          verify_aud: true
        }
      )
      user_id = decoded_token[0]['user_id']
      user = User.find(user_id)
      
      render json: {
        status: 'success',
        message: 'Token refreshed successfully',
        data: {
          token: user.generate_jwt_token,
          refresh_token: user.generate_refresh_token
        }
      }
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: {
        status: 'error',
        message: 'Invalid refresh token'
      }, status: :unauthorized
    end
  end
  
  def logout
    # In a real implementation, you might want to add the token to a denylist
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
      updated_at: user.updated_at
    }
  end
  

end




