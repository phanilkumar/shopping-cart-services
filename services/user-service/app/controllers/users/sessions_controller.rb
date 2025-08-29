# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    super
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  protected

  # The path used after sign in
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  # The path used after sign out
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
