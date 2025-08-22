# frozen_string_literal: true

# Base Application Controller for all microservices
# This provides standardized error handling, authentication, and response formatting
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # Authentication helpers will be implemented as needed
  
  # Set the layout
  layout 'application'
  
  # Handle 404 errors
  def not_found
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end
end
