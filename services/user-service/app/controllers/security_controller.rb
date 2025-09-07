# frozen_string_literal: true

class SecurityController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_not_locked

  def dashboard
    # Render the security dashboard view
  end

  # Enable two-factor authentication
  def enable_2fa
    if current_user.two_factor_enabled?
      render json: { status: 'error', message: 'Two-factor authentication is already enabled' }
      return
    end

    current_user.enable_two_factor!
    
    # Generate QR code for authenticator app
    qr_code_uri = current_user.two_factor_qr_code
    
    render json: {
      status: 'success',
      message: 'Two-factor authentication enabled',
      data: {
        qr_code_uri: qr_code_uri,
        secret: current_user.two_factor_secret
      }
    }
  end

  # Disable two-factor authentication
  def disable_2fa
    unless current_user.two_factor_enabled?
      render json: { status: 'error', message: 'Two-factor authentication is not enabled' }
      return
    end

    current_user.disable_two_factor!
    
    render json: {
      status: 'success',
      message: 'Two-factor authentication disabled'
    }
  end

  # Verify OTP code
  def verify_otp
    code = params[:otp_code]
    
    if code.blank?
      render json: { status: 'error', message: 'OTP code is required' }
      return
    end

    if current_user.verify_otp(code)
      render json: {
        status: 'success',
        message: 'OTP code verified successfully'
      }
    else
      render json: {
        status: 'error',
        message: 'Invalid OTP code'
      }, status: :unprocessable_entity
    end
  end

  # Get security status
  def security_status
    render json: {
      status: 'success',
      data: {
        two_factor_enabled: current_user.two_factor_enabled?,
        account_locked: current_user.account_locked?,
        failed_attempts: current_user.failed_attempts || 0,
        last_sign_in_at: current_user.last_sign_in_at,
        last_sign_in_ip: current_user.last_sign_in_ip,
        sign_in_count: current_user.sign_in_count || 0,
        password_changed_at: current_user.password_changed_at
      }
    }
  end

  # Unlock account (admin only)
  def unlock_account
    user = User.find(params[:user_id])
    
    unless current_user.admin?
      render json: { status: 'error', message: 'Unauthorized' }, status: :forbidden
      return
    end

    user.unlock_account!
    
    render json: {
      status: 'success',
      message: "Account unlocked for user #{user.email}"
    }
  end

  # Reset failed attempts (admin only)
  def reset_failed_attempts
    user = User.find(params[:user_id])
    
    unless current_user.admin?
      render json: { status: 'error', message: 'Unauthorized' }, status: :forbidden
      return
    end

    user.reset_failed_attempts!
    
    render json: {
      status: 'success',
      message: "Failed attempts reset for user #{user.email}"
    }
  end

  # Get QR code for 2FA setup
  def qr_code
    unless current_user.two_factor_enabled?
      render json: { status: 'error', message: 'Two-factor authentication is not enabled' }
      return
    end

    qr_code_uri = current_user.two_factor_qr_code
    
    render json: {
      status: 'success',
      data: {
        qr_code_uri: qr_code_uri,
        secret: current_user.two_factor_secret
      }
    }
  end

  private

  def ensure_user_not_locked
    if current_user.account_locked?
      render json: {
        status: 'error',
        message: 'Account is locked due to multiple failed login attempts. Please contact support.',
        locked_until: current_user.locked_at
      }, status: :locked
    end
  end
end
