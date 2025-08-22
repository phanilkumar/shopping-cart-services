# frozen_string_literal: true

# Base Application Controller for all microservices
# This provides standardized error handling, authentication, and response formatting
class BaseApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  # Standard HTTP status codes
  HTTP_STATUS = {
    ok: 200,
    created: 201,
    no_content: 204,
    bad_request: 400,
    unauthorized: 401,
    forbidden: 403,
    not_found: 404,
    unprocessable_entity: 422,
    internal_server_error: 500
  }.freeze

  # Standard response structure
  RESPONSE_STRUCTURE = {
    status: 'success',
    message: '',
    data: {},
    errors: [],
    meta: {}
  }.freeze

  # Standard error messages
  ERROR_MESSAGES = {
    unauthorized: 'Authentication required',
    forbidden: 'Access denied',
    not_found: 'Resource not found',
    invalid_params: 'Invalid parameters provided',
    server_error: 'Internal server error',
    validation_failed: 'Validation failed'
  }.freeze

  before_action :set_default_response_format
  before_action :handle_cors
  before_action :log_request

  rescue_from StandardError, with: :handle_standard_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from JWT::DecodeError, with: :handle_jwt_error
  rescue_from JWT::ExpiredSignature, with: :handle_jwt_expired

  private

  # Standard response methods
  def success_response(data = {}, message = 'Success', status = :ok, meta = {})
    render json: build_response(
      status: 'success',
      message: message,
      data: data,
      meta: meta
    ), status: HTTP_STATUS[status]
  end

  def error_response(message, errors = [], status = :unprocessable_entity, meta = {})
    render json: build_response(
      status: 'error',
      message: message,
      errors: errors,
      meta: meta
    ), status: HTTP_STATUS[status]
  end

  def build_response(status:, message: '', data: {}, errors: [], meta: {})
    {
      status: status,
      message: message,
      data: data,
      errors: errors,
      meta: meta,
      timestamp: Time.current.iso8601,
      request_id: request.request_id
    }.compact
  end

  # Authentication methods
  def authenticate_user!
    token = extract_token_from_header
    
    if token.blank?
      error_response(ERROR_MESSAGES[:unauthorized], [], :unauthorized)
      return
    end
    
    begin
      decoded_token = JWT.decode(token, jwt_secret_key, true, { algorithm: 'HS256' })
      user_id = decoded_token[0]['user_id']
      @current_user = User.find(user_id)
      
      unless @current_user.active?
        error_response('Account is not active', [], :forbidden)
        return
      end
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      error_response(ERROR_MESSAGES[:unauthorized], [], :unauthorized)
      return
    end
  end

  def current_user
    @current_user
  end

  def extract_token_from_header
    authorization_header = request.headers['Authorization']
    return nil unless authorization_header
    
    if authorization_header.start_with?('Bearer ')
      authorization_header[7..-1]
    else
      authorization_header
    end
  end

  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key'
  end

  # Error handling methods
  def handle_standard_error(exception)
    Rails.logger.error "Standard Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    error_response(
      ERROR_MESSAGES[:server_error],
      [exception.message],
      :internal_server_error
    )
  end

  def handle_not_found(exception)
    error_response(
      ERROR_MESSAGES[:not_found],
      [exception.message],
      :not_found
    )
  end

  def handle_validation_error(exception)
    error_response(
      ERROR_MESSAGES[:validation_failed],
      exception.record.errors.full_messages,
      :unprocessable_entity
    )
  end

  def handle_parameter_missing(exception)
    error_response(
      ERROR_MESSAGES[:invalid_params],
      [exception.message],
      :bad_request
    )
  end

  def handle_jwt_error(exception)
    error_response(
      'Invalid authentication token',
      [exception.message],
      :unauthorized
    )
  end

  def handle_jwt_expired(exception)
    error_response(
      'Authentication token expired',
      [exception.message],
      :unauthorized
    )
  end

  # Utility methods
  def set_default_response_format
    request.format = :json
  end

  def handle_cors
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, X-Requested-With'
  end

  def log_request
    Rails.logger.info "Request: #{request.method} #{request.path} - User: #{current_user&.id || 'anonymous'}"
  end

  # Parameter handling
  def safe_params
    params.permit!
  end

  def require_params(*required_params)
    missing_params = required_params.select { |param| params[param].blank? }
    
    if missing_params.any?
      error_response(
        'Missing required parameters',
        missing_params.map { |param| "#{param} is required" },
        :bad_request
      )
      return false
    end
    
    true
  end

  # Pagination helpers
  def paginate(collection, per_page = 20)
    page = params[:page]&.to_i || 1
    per_page = [per_page, 100].min # Cap at 100 items per page
    
    collection.page(page).per(per_page)
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end

  # Serialization helpers
  def serialize_resource(resource, serializer_class = nil)
    return {} if resource.nil?
    
    if serializer_class
      serializer_class.new(resource).as_json
    else
      resource.as_json
    end
  end

  def serialize_collection(collection, serializer_class = nil)
    return [] if collection.nil?
    
    if serializer_class
      ActiveModel::Serializer::CollectionSerializer.new(collection, serializer: serializer_class).as_json
    else
      collection.as_json
    end
  end
end
