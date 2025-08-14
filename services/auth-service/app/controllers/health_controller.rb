class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  
  def check
    render json: {
      status: 'healthy',
      service: 'auth-service',
      timestamp: Time.current,
      version: '1.0.0'
    }
  end
end
