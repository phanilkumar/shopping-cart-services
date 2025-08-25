# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json
  skip_before_action :verify_authenticity_token, if: :json_request?

  # GET /users/sign_up
  def new
    super
  end

  # POST /users
  def create
    super
  end

  # GET /users/edit
  def edit
    super
  end

  # PUT /users
  def update
    super
  end

  # DELETE /users
  def destroy
    super
  end

  private

  def json_request?
    request.format.json?
  end

  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :password, :password_confirmation, :role, :status)
  end

  def account_update_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :password, :password_confirmation, :current_password, :role, :status)
  end

  def respond_with(resource, _opts = {})
    if request.format.json?
      if resource.persisted?
        render json: {
          status: { code: 200, message: 'Signed up successfully.' },
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
          status: { code: 422, message: "User couldn't be created successfully. " },
          errors: resource.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      # For HTML requests, let Devise handle the default behavior
      super
    end
  end
end
