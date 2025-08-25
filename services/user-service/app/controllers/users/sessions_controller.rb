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
        render json: {
          status: { code: 401, message: 'Invalid email or password.' }
        }, status: :unauthorized
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
