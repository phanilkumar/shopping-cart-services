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
        user: user_serializer(@user),
        oauth_accounts: oauth_accounts_serializer(@user.oauth_accounts)
      }
    }
  end
  
  private
  
  def set_user
    @user = current_user
  end
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone)
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
      connected_providers: user.connected_providers,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
  
  def oauth_accounts_serializer(oauth_accounts)
    oauth_accounts.map do |account|
      {
        id: account.id,
        provider: account.provider,
        provider_name: account.provider_name,
        provider_icon: account.provider_icon,
        provider_uid: account.provider_uid,
        active: account.active?,
        expired: account.expired?,
        expires_at: account.expires_at,
        created_at: account.created_at,
        updated_at: account.updated_at
      }
    end
  end
end
