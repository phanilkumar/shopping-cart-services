class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :update, :profile]
  
  def show
    render json: {
      status: 'success',
      data: {
        user: user_serializer(@user)
      }
    }
  end
  
  def update
    if @user.update(user_params)
      render json: {
        status: 'success',
        message: 'User updated successfully',
        data: {
          user: user_serializer(@user)
        }
      }
    else
      render json: {
        status: 'error',
        message: 'Update failed',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def profile
    render json: {
      status: 'success',
      data: {
        user: user_serializer(@user)
      }
    }
  end
  
  private
  
  def set_user
    @user = current_user
  end
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :status, :role)
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
