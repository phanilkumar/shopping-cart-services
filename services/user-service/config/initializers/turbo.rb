# frozen_string_literal: true

# Turbo configuration for Hotwire
Rails.application.config.after_initialize do
  # Configure Turbo to work with Devise
  Rails.application.config.to_prepare do
    # Turbo doesn't work with devise by default.
    # Keep tabs on https://github.com/heartcombo/devise/issues/5446 for a future fix
    Devise::FailureApp.class_eval do
      def respond
        if request_format == :turbo_stream
          redirect
        else
          super
        end
      end
      
      def redirect
        store_location!
        if flash[:alert]
          redirect_to redirect_url, status: :see_other, alert: flash[:alert]
        else
          redirect_to redirect_url, status: :see_other
        end
      end
    end
  end
end

# Configure Turbo Drive
Turbo.configure do |config|
  # Enable/disable Turbo Drive globally
  config.drive_enabled = true
  
  # Configure how forms are submitted
  config.default_submission_method = :post
end if defined?(Turbo)