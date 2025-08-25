class AuthController < ApplicationController
  layout 'application'
  skip_before_action :verify_authenticity_token, only: [:create_login]
  
  # GET /login
  def login
    # Show login page
    redirect_to new_user_session_path
  end
  
  # POST /login (for email/password authentication)
  def create_login
    identifier = params[:identifier]
    password = params[:password]
    
    # Determine if identifier is email or phone
    if identifier.include?('@')
      # Email authentication
      user = User.find_by(email: identifier.downcase)
      
      if user&.valid_password?(password)
        # For now, just show success message
        flash[:notice] = "Welcome back, #{user.display_name}!"
        redirect_to dashboard_path
      else
        # Return JSON error for AJAX requests, or redirect for regular requests
        if request.xhr? || request.format.json?
          render json: { 
            status: 'error', 
            message: 'Incorrect password. Please try again.' 
          }, status: :unauthorized
        else
          flash[:alert] = 'Incorrect password. Please try again.'
          redirect_to login_path
        end
      end
    else
      # Phone authentication (should not reach here from password form)
      if request.xhr? || request.format.json?
        render json: { 
          status: 'error', 
          message: 'Invalid authentication method' 
        }, status: :bad_request
      else
        flash[:alert] = 'Invalid authentication method'
        redirect_to login_path
      end
    end
  end
  
  # GET /register (show registration form)
  def register
    @user = User.new
  end
  
  # POST /register (handle registration form submission)
  def create_register
    @user = User.new(user_params)
    
    if @user.save
      # Show congratulations message
      flash[:notice] = 'Registration successful! Please login with your credentials.'
      redirect_to login_path
    else
      # Re-render the registration form with errors
      flash.now[:alert] = 'Registration failed. Please check the form and try again.'
      render :register, status: :unprocessable_entity
    end
  end
  
  # DELETE /logout
  def logout
    sign_out(current_user)
    flash[:notice] = 'You have been successfully logged out.'
    redirect_to root_path
  end
  
  # GET /congratulations
  def congratulations
    if user_signed_in?
      @user = current_user
    else
      redirect_to root_path
    end
  end

  # GET /dashboard
  def dashboard
    if user_signed_in?
      # User is authenticated, show dashboard
      @user = current_user
    else
      # User is not authenticated, redirect to home
      flash[:alert] = 'Please log in to access the dashboard.'
      redirect_to root_path
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, 
                               :first_name, :last_name, :phone)
  end
end
