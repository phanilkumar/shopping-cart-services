class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate_user!
  
  def profile
    success_response(
      user_serializer(current_user),
      'Profile retrieved successfully'
    )
  end
  
  def show
    user = User.find(params[:id])
    
    # Only allow users to view their own profile or admin to view any profile
    unless current_user.id == user.id || current_user.admin?
      error_response('Access denied', [], :forbidden)
      return
    end
    
    success_response(
      user_serializer(user),
      'User details retrieved successfully'
    )
  end
  
  def update_profile
    if current_user.update(user_params)
      success_response(
        user_serializer(current_user),
        'Profile updated successfully'
      )
    else
      error_response(
        'Profile update failed',
        current_user.errors.full_messages,
        :unprocessable_entity
      )
    end
  end
  
  def update
    user = User.find(params[:id])
    
    # Only allow users to update their own profile or admin to update any profile
    unless current_user.id == user.id || current_user.admin?
      error_response('Access denied', [], :forbidden)
      return
    end
    
    if user.update(user_params)
      success_response(
        user_serializer(user),
        'User updated successfully'
      )
    else
      error_response(
        'User update failed',
        user.errors.full_messages,
        :unprocessable_entity
      )
    end
  end
  
  def destroy
    user = User.find(params[:id])
    
    # Only allow users to delete their own account or admin to delete any account
    unless current_user.id == user.id || current_user.admin?
      error_response('Access denied', [], :forbidden)
      return
    end
    
    if user.destroy
      success_response(
        {},
        'User deleted successfully'
      )
    else
      error_response(
        'User deletion failed',
        user.errors.full_messages,
        :unprocessable_entity
      )
    end
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
      updated_at: user.updated_at,
      two_factor_enabled: user.two_factor_enabled?,
      account_locked: user.account_locked?
    }
  end
  
  private
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :email)
  end
end

