class Api::V1::OtpController < ApplicationController
  skip_before_action :authenticate_user!, only: [:send_otp, :verify_otp, :login_with_otp]

  # Send OTP to phone number
  def send_otp
    phone = params[:phone]
    
    # Validate phone number format
    unless phone&.match?(/\A[6-9]\d{9}\z/)
      return render json: {
        status: 'error',
        message: 'Invalid phone number format. Please enter a valid 10-digit mobile number.'
      }, status: :bad_request
    end

    # Add country code for storage
    phone_with_code = "+91#{phone}"
    
    # Find or create user
    user = User.find_by(phone: phone_with_code)
    
    if user.nil?
      # Create a new user with phone number only
      user = User.new(
        phone: phone_with_code,
        email: "#{phone}@temp.com", # Temporary email
        first_name: "User",
        last_name: phone,
        password: SecureRandom.hex(8), # Temporary password
        status: 1, # Active
        role: 0 # User role
      )
      
      unless user.save
        error_messages = user.errors.full_messages
        if user.errors[:phone].include?('Phone number is already registered')
          return render json: {
            status: 'error',
            message: 'Phone number is already registered. Please use a different number or login with existing account.'
          }, status: :unprocessable_entity
        elsif user.errors[:email].include?('Email address is already registered')
          return render json: {
            status: 'error',
            message: 'Email address is already registered. Please use a different email or login with existing account.'
          }, status: :unprocessable_entity
        else
          return render json: {
            status: 'error',
            message: 'Failed to create user account',
            errors: error_messages
          }, status: :unprocessable_entity
        end
      end
    end

    # Generate static OTP (123456 for all numbers as requested)
    otp = "123456"
    
    # Store OTP in session or cache (for demo, we'll use a simple approach)
    Rails.cache.write("otp_#{phone}", otp, expires_in: 10.minutes)
    
    # In a real application, you would send SMS here
    # For now, we'll just return success
    
    render json: {
      status: 'success',
      message: "OTP sent successfully to #{phone}. Use OTP: #{otp} for testing."
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
        message: 'Invalid phone number format'
      }, status: :bad_request
    end
    
    unless otp&.match?(/\A\d{6}\z/)
      return render json: {
        status: 'error',
        message: 'Invalid OTP format. Please enter 6 digits.'
      }, status: :bad_request
    end

    # Check stored OTP
    stored_otp = Rails.cache.read("otp_#{phone}")
    
    if stored_otp.nil?
      return render json: {
        status: 'error',
        message: 'OTP expired or not found. Please request a new OTP.'
      }, status: :bad_request
    end
    
    if stored_otp != otp
      return render json: {
        status: 'error',
        message: 'Invalid OTP. Please check and try again.'
      }, status: :bad_request
    end

    # OTP is valid
    Rails.cache.delete("otp_#{phone}") # Clear OTP after verification
    
    render json: {
      status: 'success',
      message: 'OTP verified successfully'
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
        message: 'Invalid phone number format'
      }, status: :bad_request
    end
    
    unless otp&.match?(/\A\d{6}\z/)
      return render json: {
        status: 'error',
        message: 'Invalid OTP format'
      }, status: :bad_request
    end

    # Check stored OTP
    stored_otp = Rails.cache.read("otp_#{phone}")
    
    if stored_otp.nil?
      return render json: {
        status: 'error',
        message: 'OTP expired or not found. Please request a new OTP.'
      }, status: :bad_request
    end
    
    if stored_otp != otp
      return render json: {
        status: 'error',
        message: 'Invalid OTP. Please check and try again.'
      }, status: :bad_request
    end

    # Find user
    phone_with_code = "+91#{phone}"
    user = User.find_by(phone: phone_with_code)
    
    if user.nil?
      return render json: {
        status: 'error',
        message: 'User not found. Please register first.'
      }, status: :not_found
    end

    # Check if user is active
    unless user.active?
      return render json: {
        status: 'error',
        message: 'Account is not active. Please contact support.'
      }, status: :forbidden
    end

    # Update last login
    user.update_last_login
    
    # Generate tokens
    token = user.generate_jwt_token
    refresh_token = user.generate_refresh_token
    
    # Clear OTP after successful login
    Rails.cache.delete("otp_#{phone}")
    
    render json: {
      status: 'success',
      message: 'Login successful',
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

  private

  def otp_params
    params.permit(:phone, :otp)
  end
end
