class Api::V1::PasswordsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:forgot, :reset]
  before_action :authenticate_user!, only: [:change]
  
  def forgot
    user = User.find_by(email: params[:email])
    
    if user
      user.send_password_reset_email
      render json: {
        status: 'success',
        message: 'Password reset instructions sent to your email'
      }
    else
      render json: {
        status: 'error',
        message: 'Email not found'
      }, status: :not_found
    end
  end
  
  def reset
    user = User.find_by(password_reset_token: params[:token])
    
    if user&.password_reset_token_valid?(params[:token])
      if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        user.update(password_reset_token: nil, password_reset_sent_at: nil)
        render json: {
          status: 'success',
          message: 'Password reset successfully'
        }
      else
        render json: {
          status: 'error',
          message: 'Password reset failed',
          errors: user.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: {
        status: 'error',
        message: 'Invalid or expired reset token'
      }, status: :unauthorized
    end
  end
  
  def change
    if current_user.valid_password?(params[:current_password])
      if current_user.update(password: params[:new_password], password_confirmation: params[:new_password_confirmation])
        render json: {
          status: 'success',
          message: 'Password changed successfully'
        }
      else
        render json: {
          status: 'error',
          message: 'Password change failed',
          errors: current_user.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: {
        status: 'error',
        message: 'Current password is incorrect'
      }, status: :unauthorized
    end
  end
end
