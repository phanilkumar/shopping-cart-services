class Api::V1::OtpController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:send_otp, :verify_otp, :login_with_otp, :validate_email]

  # Send OTP to phone number
  def send_otp
    phone = params[:phone]
    
    # Rate limiting: Check if OTP was sent recently
    rate_limit_key = "rate_limit_#{phone}"
    last_sent = Rails.cache.read(rate_limit_key)
    
    if last_sent && last_sent > 1.minute.ago
      return render json: {
        status: 'error',
        message: 'Please wait 1 minute before requesting another OTP.'
      }, status: :too_many_requests
    end
    
    # Validate phone number format
    unless phone&.match?(/\A[6-9]\d{9}\z/)
      return render json: {
        status: 'error',
        message: 'Invalid phone number format. Enter a 10-digit number starting with 6, 7, 8, or 9.'
      }, status: :bad_request
    end

    # Add country code for storage
    phone_with_code = "+91#{phone}"
    
    # Find user - only allow OTP for registered users
    user = User.find_by(phone: phone_with_code)
    
    if user.nil?
      return render json: {
        status: 'error',
        message: 'Phone number not found in system. Registration required.'
      }, status: :not_found
    end

    # Check if user is active
    unless user.active?
      return render json: {
        status: 'error',
        message: 'Account suspended. Contact support for assistance.'
      }, status: :forbidden
    end

    # Generate static OTP (123456 for all numbers as requested)
    otp = "123456"
    
    # Store OTP in Redis cache with 5-minute expiration for security
    Rails.cache.write("otp_#{phone}", { 
      code: otp, 
      expires_at: 5.minutes.from_now,
      attempts: 0,
      max_attempts: 3
    }, expires_in: 5.minutes)
    
    # Set rate limiting (1 minute cooldown)
    Rails.cache.write(rate_limit_key, Time.current, expires_in: 1.minute)
    
    Rails.logger.info "OTP stored for #{phone}: #{otp}"
    Rails.logger.info "Session data: #{Rails.cache.read("otp_#{phone}").inspect}"
    
    # In a real application, you would send SMS here
    # For now, we'll just return success
    
    render json: {
      status: 'success',
      message: "Verification code sent to #{phone}"
    }
  end

  # Verify OTP
  def verify_otp
    phone = params[:phone]
    otp = params[:otp]
    
    # Validate inputs
    unless phone&.match?(/\A[6-9]\d{9}\z/)
      return render json: {
        status: 'error',
        message: 'Invalid phone number format.'
      }, status: :bad_request
    end
    
    unless otp&.match?(/\A\d{6}\z/)
      return render json: {
        status: 'error',
        message: 'Invalid verification code format. Enter 6 digits.'
      }, status: :bad_request
    end

    # Check stored OTP
    stored_otp_data = Rails.cache.read("otp_#{phone}")
    
    if stored_otp_data.nil?
      return render json: {
        status: 'error',
        message: 'Verification code expired. Request new code.'
      }, status: :bad_request
    end
    
    # Check if OTP has expired
    if stored_otp_data[:expires_at] < Time.current
      Rails.cache.delete("otp_#{phone}")
      return render json: {
        status: 'error',
        message: 'Verification code expired. Request new code.'
      }, status: :bad_request
    end
    
    # Check attempt limits
    if stored_otp_data[:attempts] >= stored_otp_data[:max_attempts]
      Rails.cache.delete("otp_#{phone}")
      return render json: {
        status: 'error',
        message: 'Too many failed attempts. Request new code.'
      }, status: :bad_request
    end
    
    stored_otp = stored_otp_data[:code]
    Rails.logger.info "Stored OTP for #{phone}: #{stored_otp}"
    Rails.logger.info "Attempts: #{stored_otp_data[:attempts]}/#{stored_otp_data[:max_attempts]}"
    
    if stored_otp != otp
      # Increment attempt counter
      stored_otp_data[:attempts] += 1
      Rails.cache.write("otp_#{phone}", stored_otp_data, expires_in: 5.minutes)
      
      remaining_attempts = stored_otp_data[:max_attempts] - stored_otp_data[:attempts]
      return render json: {
        status: 'error',
        message: "Incorrect verification code. #{remaining_attempts} attempts remaining."
      }, status: :bad_request
    end

    # OTP is valid - clear it from cache
    Rails.cache.delete("otp_#{phone}")
    
    render json: {
      status: 'success',
      message: 'Verification successful'
    }
  end

  # Login with OTP
  def login_with_otp
    phone = params[:phone]
    otp = params[:otp]
    
    # Validate inputs
    unless phone&.match?(/\A[6-9]\d{9}\z/)
      return render json: {
        status: 'error',
        message: 'Invalid phone number format.'
      }, status: :bad_request
    end
    
    unless otp&.match?(/\A\d{6}\z/)
      return render json: {
        status: 'error',
        message: 'Invalid verification code format. Enter 6 digits.'
      }, status: :bad_request
    end

    # Find user
    phone_with_code = "+91#{phone}"
    user = User.find_by(phone: phone_with_code)
    
    if user.nil?
      return render json: {
        status: 'error',
        message: 'Account not found. Registration required.'
      }, status: :not_found
    end

    # Check if account is locked (same as email login)
    if user.account_locked?
      remaining_time = user.lockout_remaining_time
      expires_at = user.lockout_expires_at
      
      return render json: {
        status: 'error',
        message: "Account is locked due to multiple failed login attempts. Will automatically unlock in #{remaining_time} seconds.",
        locked_until: user.locked_at,
        expires_at: expires_at,
        remaining_seconds: remaining_time,
        auto_unlock: true
      }, status: :locked
    end

    # Check if user is active
    unless user.active?
      return render json: {
        status: 'error',
        message: 'Account suspended. Contact support for assistance.'
      }, status: :forbidden
    end

    # Check stored OTP
    stored_otp_data = Rails.cache.read("otp_#{phone}")
    stored_otp = stored_otp_data[:code] if stored_otp_data
    
    # Check if OTP has expired
    if stored_otp_data && stored_otp_data[:expires_at] < Time.current
      Rails.cache.delete("otp_#{phone}")
      stored_otp = nil
    end
    Rails.logger.info "Stored OTP for #{phone}: #{stored_otp}"
    Rails.logger.info "Session data for #{phone}: #{Rails.cache.read("otp_#{phone}").inspect}"
    
    if stored_otp.nil?
      return render json: {
        status: 'error',
        message: 'Verification code expired. Request new code.'
      }, status: :bad_request
    end

    if stored_otp != otp
      # Increment failed attempts for OTP failures (same as email login)
      user.increment_failed_attempts!
      
      # Log failed OTP attempt
      AuditLog.log_login_failure(user.email, request) if defined?(AuditLog)
      Rails.logger.warn "Failed OTP attempt for user #{user.id} (#{user.email}) from IP: #{request.remote_ip}"
      
      # Check if account should be locked after failed OTP attempt
      if user.account_locked?
        remaining_time = user.lockout_remaining_time
        expires_at = user.lockout_expires_at
        
        return render json: {
          status: 'error',
          message: "Account locked due to multiple failed login attempts. Will automatically unlock in #{remaining_time} seconds.",
          locked_until: user.locked_at,
          expires_at: expires_at,
          remaining_seconds: remaining_time,
          auto_unlock: true
        }, status: :locked
      end
      
      # Show remaining attempts
      remaining_attempts = 5 - (user.failed_attempts || 0)
      return render json: {
        status: 'error',
        message: "Incorrect verification code. #{remaining_attempts} attempts remaining.",
        remaining_attempts: remaining_attempts
      }, status: :bad_request
    end

    # OTP is valid - clear it from cache
    Rails.cache.delete("otp_#{phone}") # Clear OTP after verification

    # Reset failed attempts on successful login (same as email login)
    user.reset_failed_attempts!
    user.update_last_login
    
    # Log successful login
    AuditLog.log_login_success(user, request) if defined?(AuditLog)
    Rails.logger.info "Successful OTP login for user #{user.id} (#{user.email}) from IP: #{request.remote_ip}"

    # Generate JWT token
    token = JWT.encode(
      {
        user_id: user.id,
        email: user.email,
        exp: 24.hours.from_now.to_i
      },
      Rails.application.secrets.secret_key_base,
      'HS256'
    )

    # Generate refresh token
    refresh_token = SecureRandom.hex(32)

    render json: {
      status: 'success',
      message: 'Authentication successful',
      data: {
        user: {
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
        },
        token: token,
        refresh_token: refresh_token
      }
    }
  end

  def validate_email
    email = params[:email]&.downcase&.strip
    
    unless email&.match?(URI::MailTo::EMAIL_REGEXP)
      return render json: {
        status: "error",
        message: "Invalid email format."
      }, status: :bad_request
    end
    
    user = User.find_by(email: email)
    
    if user.nil?
      return render json: {
        status: "error",
        message: "Email not found in system. Registration required."
      }, status: :not_found
    end
    
    unless user.active?
      return render json: {
        status: "error",
        message: "Account suspended. Contact support for assistance."
      }, status: :forbidden
    end
    
    render json: {
      status: "success",
      message: "Email validated successfully"
    }
  end
end
