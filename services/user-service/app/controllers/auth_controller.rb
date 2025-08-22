class AuthController < ApplicationController
  layout 'application'
  skip_before_action :verify_authenticity_token, only: [:create_login]
  
  # GET /login
  def login
    # Handle JSON requests (should not happen, but just in case)
    if request.format.json?
      render json: { 
        status: 'error', 
        message: 'GET request not allowed for authentication. Use POST.' 
      }, status: :method_not_allowed
    else
      # For now, just render the login page
    end
  end
  
  # POST /login (for email/password authentication)
  def create_login
    identifier = params[:identifier]
    password = params[:password]
    
    # Determine if identifier is email or phone
    if identifier.include?('@')
      # Email authentication
      user = User.find_by(email: identifier.downcase)
      
      if user&.authenticate(password)
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
  
  # GET /register
  def register
    @user = User.new
  end
  
  # POST /register
  def create_register
    @user = User.new(user_params)
    
    if @user.save
      # Show congratulations message
      flash[:notice] = 'Registration successful! Please login with your credentials.'
      redirect_to login_path
    else
      render :register, status: :unprocessable_entity
    end
  end
  
  # DELETE /logout
  def logout
    flash[:notice] = 'Logout functionality will be implemented with Devise'
    redirect_to login_path
  end
  
  # GET /dashboard
  def dashboard
    flash[:notice] = 'Dashboard functionality will be implemented with Devise'
    redirect_to login_path
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, 
                               :first_name, :last_name, :phone)
  end
end
