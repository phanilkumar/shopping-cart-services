# frozen_string_literal: true

# Base Application Controller for all microservices
# This provides standardized error handling, authentication, and response formatting
class ApplicationController < ActionController::Base
  include LocaleConcern
  
  protect_from_forgery with: :exception, unless: :json_request?
  
  # Set the layout
  layout 'application'
  
  # Security headers
  before_action :set_security_headers
  
  # Audit logging
  after_action :log_authentication_events
  
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

  # Set security headers
  def set_security_headers
    # X-Frame-Options: Prevents clickjacking
    response.headers['X-Frame-Options'] = 'DENY'
    
    # X-Content-Type-Options: Prevents MIME sniffing
    response.headers['X-Content-Type-Options'] = 'nosniff'
    
    # X-XSS-Protection: XSS protection
    response.headers['X-XSS-Protection'] = '1; mode=block'
    
    # X-Download-Options: Prevents IE from executing downloads
    response.headers['X-Download-Options'] = 'noopen'
    
    # X-Permitted-Cross-Domain-Policies: Controls Adobe Flash and Adobe Acrobat
    response.headers['X-Permitted-Cross-Domain-Policies'] = 'none'
    
    # Referrer-Policy: Controls referrer information
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    
    # Strict-Transport-Security: Enforces HTTPS
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
    
    # Content-Security-Policy: Controls resource loading
    response.headers['Content-Security-Policy'] = [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net",
      "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net data:",
      "img-src 'self' data: https:",
      "font-src 'self' https:",
      "connect-src 'self'",
      "media-src 'self'",
      "object-src 'none'",
      "frame-src 'none'",
      "worker-src 'self'",
      "manifest-src 'self'",
      "form-action 'self'",
      "base-uri 'self'",
      "upgrade-insecure-requests"
    ].join('; ')
  end

  # Log authentication events
  def log_authentication_events
    # Log authentication-related actions
    if controller_name == 'sessions' || controller_name == 'registrations'
      action = action_name
      user_id = current_user&.id || 'anonymous'
      ip_address = request.remote_ip
      
      case action
      when 'create'
        if controller_name == 'sessions'
          Rails.logger.info "Authentication event: login from IP #{ip_address} at #{Time.current}"
        elsif controller_name == 'registrations'
          Rails.logger.info "Authentication event: registration from IP #{ip_address} at #{Time.current}"
        end
      when 'destroy'
        Rails.logger.info "Authentication event: logout from IP #{ip_address} at #{Time.current}"
      end
    end
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
end
