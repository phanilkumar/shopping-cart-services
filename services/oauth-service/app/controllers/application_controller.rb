class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  before_action :authenticate_user!
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request
  
  private
  
  def authenticate_user!
    token = extract_token_from_header
    
    if token
      begin
        decoded_token = JWT.decode(token, jwt_secret_key, true, { algorithm: 'HS256' })
        user_id = decoded_token[0]['user_id']
        @current_user = User.find(user_id)
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render json: {
          status: 'error',
          message: 'Invalid or expired token'
        }, status: :unauthorized
      end
    else
      render json: {
        status: 'error',
        message: 'Authentication token required'
      }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
  
  def extract_token_from_header
    authorization_header = request.headers['Authorization']
    return nil unless authorization_header
    
    token = authorization_header.split(' ').last
    token if token.present?
  end
  
  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key'
  end
  
  def not_found(exception)
    render json: {
      status: 'error',
      message: 'Resource not found',
      error: exception.message
    }, status: :not_found
  end
  
  def unprocessable_entity(exception)
    render json: {
      status: 'error',
      message: 'Validation failed',
      errors: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end
  
  def bad_request(exception)
    render json: {
      status: 'error',
      message: 'Bad request',
      error: exception.message
    }, status: :bad_request
  end
  
  def not_found
    render json: {
      status: 'error',
      message: 'Endpoint not found'
    }, status: :not_found
  end
end
