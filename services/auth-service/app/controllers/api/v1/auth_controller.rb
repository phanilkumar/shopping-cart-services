class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :register]
  
  def login
    user = User.find_by(email: params[:email])
    
    if user&.valid_password?(params[:password])
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
      render json: {
        status: 'error',
        message: 'Registration failed',
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def refresh
    begin
      decoded_token = JWT.decode(params[:refresh_token], jwt_secret_key, true, { algorithm: 'HS256' })
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
  
  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key'
  end
end
