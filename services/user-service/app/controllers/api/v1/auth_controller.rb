class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token, only: [:login, :register]
  
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
      
      Rails.logger.warn "Failed registration attempt for email: #{params.dig(:user, :email)} from IP #{request.remote_ip}"
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
      Rails.logger.warn "Invalid refresh token attempt from IP #{request.remote_ip}"
      error_response('Invalid refresh token', [], :unauthorized)
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
    Rails.application.credentials.secret_key_base
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
