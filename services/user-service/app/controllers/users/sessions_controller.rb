# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  respond_to :html, :json
  skip_before_action :verify_authenticity_token, if: :json_request?

  # GET /users/sign_in
  def new
    super
  end

  # POST /users/sign_in
  def create
    # Check if user exists and is locked before attempting login
    email = params[:user]&.dig(:email) || params[:email]
    if email.present?
      user = User.find_by(email: email)
      if user&.account_locked?
        if request.format.json?
          remaining_time = user.lockout_remaining_time
          expires_at = user.lockout_expires_at
          
          render json: {
            status: 'error',
            message: "Account is locked due to multiple failed login attempts. Will automatically unlock in #{remaining_time} seconds.",
            locked_until: user.locked_at,
            expires_at: expires_at,
            remaining_seconds: remaining_time,
            auto_unlock: true
          }, status: :locked
          return
        else
          # For HTML requests, show flash message
          flash[:alert] = "Account is locked due to multiple failed login attempts. Will automatically unlock in #{user.lockout_remaining_time} seconds."
          redirect_to new_user_session_path
          return
        end
      end
    end
    
    super
  end

  # DELETE /users/sign_out
  def destroy
    super
  end

  private

  def json_request?
    request.format.json?
  end

  def respond_with(resource, _opts = {})
    if request.format.json?
      if resource.persisted?
        render json: {
          status: { code: 200, message: 'Logged in successfully.' },
          data: {
            user: {
              id: resource.id,
              email: resource.email,
              first_name: resource.first_name,
              last_name: resource.last_name,
              display_name: resource.display_name,
              role: resource.role,
              status: resource.status
            }
          }
        }
      else
        # Check if the resource (user) is locked
        if resource&.account_locked?
          remaining_time = resource.lockout_remaining_time
          expires_at = resource.lockout_expires_at
          
          render json: {
            status: { code: 423, message: "Account is locked due to multiple failed login attempts. Will automatically unlock in #{remaining_time} seconds." },
            locked_until: resource.locked_at,
            expires_at: expires_at,
            remaining_seconds: remaining_time,
            auto_unlock: true
          }, status: :locked
        else
          render json: {
            status: { code: 401, message: 'Invalid email or password.' }
          }, status: :unauthorized
        end
      end
    else
      # For HTML requests, redirect to congratulations page after successful login
      if resource.persisted?
        redirect_to congratulations_path, notice: "Welcome back, #{resource.display_name}!"
      else
        super
      end
    end
  end

  def respond_to_on_destroy
    if request.format.json?
      if current_user
        render json: {
          status: 200,
          message: 'Logged out successfully.'
        }
      else
        render json: {
          status: 401,
          message: "Couldn't find an active session."
        }
      end
    else
      # For HTML requests, let Devise handle the default behavior
      super
    end
  end
end
