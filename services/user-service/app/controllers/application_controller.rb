# frozen_string_literal: true

# Base Application Controller for all microservices
# This provides standardized error handling, authentication, and response formatting
class ApplicationController < ActionController::Base
  include LocaleConcern
  
  # Security headers
  before_action :set_security_headers
  
  # Prevent CSRF attacks
  protect_from_forgery with: :exception
  
  # Set locale
  before_action :set_locale
  
  # Set the layout
  layout 'application'
  
  # Devise authentication helpers - temporarily commented out
  # before_action :authenticate_user!, unless: :devise_controller?

  # Handle JSON requests
  respond_to :html, :json

  # Health check endpoint for Docker
  def health
    render json: { status: 'healthy', timestamp: Time.current }, status: :ok
  end

  # Handle 404 errors
  def not_found
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

  # Custom JSON response methods
  def success_response(data = {}, message = 'Success', status = :ok)
    render json: {
      status: 'success',
      message: message,
      data: data
    }, status: status
  end

  def error_response(message, errors = [], status = :unprocessable_entity)
    render json: {
      status: 'error',
      message: message,
      errors: errors
    }, status: status
  end

  private

  def json_request?
    request.format.json?
  end

  # Override Devise's after_sign_in_path_for
  def after_sign_in_path_for(resource)
    if request.format.json?
      # For API requests, return JSON response
      render json: {
        status: 'success',
        message: 'Signed in successfully',
        data: {
          user: {
            id: resource.id,
            email: resource.email,
            first_name: resource.first_name,
            last_name: resource.last_name,
            display_name: resource.display_name
          }
        }
      }
    else
      # For web requests, redirect to dashboard
      dashboard_path
    end
  end

  # Override Devise's after_sign_out_path_for
  def after_sign_out_path_for(resource_or_scope)
    if request.format.json?
      # For API requests, return JSON response
      render json: {
        status: 'success',
        message: 'Signed out successfully'
      }
    else
      # For web requests, redirect to login
      new_user_session_path
    end
  end

  def set_security_headers
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    response.headers['Content-Security-Policy'] = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data: https://cdn.jsdelivr.net; connect-src 'self' ws: wss:;"
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains' if Rails.env.production?
  end
  
  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
  end
  
  def extract_locale
    parsed_locale = params[:locale] || request.headers['Accept-Language']&.scan(/^[a-z]{2}/)&.first
    parsed_locale if I18n.available_locales.map(&:to_s).include?(parsed_locale)
  end
  
  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end
