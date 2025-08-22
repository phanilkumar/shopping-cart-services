class OtpController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:send_otp, :login_with_otp]
  
  # POST /api/v1/auth/send-otp
  def send_otp
    phone = params[:phone]
    
    if phone.blank?
      render json: { error: 'Phone number is required' }, status: :bad_request
      return
    end
    
    # Find user by phone number
    user = User.find_by(phone: phone)
    
    if user.nil?
      render json: { error: 'Phone number not found' }, status: :not_found
      return
    end
    
    # Generate 6-digit OTP
    otp = generate_otp
    
    # Store OTP in session (in production, use Redis or database)
    session["otp_#{phone}"] = {
      code: otp,
      expires_at: 5.minutes.from_now,
      attempts: 0
    }
    
    # For demo purposes, we'll return the OTP in the response
    # In production, this would be sent via SMS
    render json: { 
      message: 'OTP sent successfully',
      otp: otp, # Remove this in production
      expires_in: 300 # 5 minutes
    }
  end
  
  # POST /api/v1/auth/login-with-otp
  def login_with_otp
    phone = params[:phone]
    otp = params[:otp]
    
    if phone.blank? || otp.blank?
      render json: { error: 'Phone number and OTP are required' }, status: :bad_request
      return
    end
    
    # Find user by phone number
    user = User.find_by(phone: phone)
    
    if user.nil?
      render json: { error: 'Phone number not found' }, status: :not_found
      return
    end
    
    # Verify OTP
    stored_otp_data = session["otp_#{phone}"]
    
    if stored_otp_data.nil?
      render json: { error: 'OTP expired or not found' }, status: :unauthorized
      return
    end
    
    if stored_otp_data[:expires_at] < Time.current
      session.delete("otp_#{phone}")
      render json: { error: 'OTP has expired' }, status: :unauthorized
      return
    end
    
    if stored_otp_data[:attempts] >= 3
      session.delete("otp_#{phone}")
      render json: { error: 'Too many failed attempts' }, status: :unauthorized
      return
    end
    
    if stored_otp_data[:code] != otp
      stored_otp_data[:attempts] += 1
      session["otp_#{phone}"] = stored_otp_data
      render json: { error: 'Invalid OTP' }, status: :unauthorized
      return
    end
    
    # OTP is valid - clear it from session
    session.delete("otp_#{phone}")
    
    # Update last login
    user.update(last_login_at: Time.current)
    
    # For now, redirect to dashboard with success message
    flash[:notice] = "Welcome back, #{user.display_name}!"
    redirect_to dashboard_path
  end
  
  private
  
  def generate_otp
    # Generate a 6-digit OTP
    sprintf('%06d', rand(100000..999999))
  end
end
