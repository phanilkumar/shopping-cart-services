# frozen_string_literal: true

# Standardized API Controller Template
# All API controllers should inherit from BaseApplicationController and follow this structure
class Api::V1::BaseController < BaseApplicationController
  # Standard API versioning
  API_VERSION = 'v1'.freeze
  
  # Standard pagination defaults
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100
  
  # Standard response headers
  before_action :set_response_headers
  
  # Standard logging
  before_action :log_api_request
  after_action :log_api_response
  
  # Standard rate limiting (implement in subclasses)
  before_action :check_rate_limit
  
  # Handle JSON parsing errors
  rescue_from JSON::ParserError, with: :handle_json_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from ActionController::UnpermittedParameters, with: :handle_unpermitted_parameters
  
  # Handle malformed JSON in request body
  before_action :validate_json_format
  
  # Standard API documentation
  include Swagger::Blocks if defined?(Swagger::Blocks)
  
  private
  
  # Validate JSON format for POST/PUT requests
  def validate_json_format
    return unless request.post? || request.put? || request.patch?
    return unless request.content_type&.include?('application/json')
    
    begin
      JSON.parse(request.body.read)
      request.body.rewind # Reset body for later reading
    rescue JSON::ParserError => e
      handle_json_error(e)
    end
  end
  
  # Standard response headers
  def set_response_headers
    response.headers['X-API-Version'] = API_VERSION
    response.headers['X-Request-ID'] = request.request_id
    response.headers['X-Response-Time'] = Time.current.to_f.to_s
  end
  
  # Standard logging
  def log_api_request
    Rails.logger.info "API Request: #{request.method} #{request.path} - User: #{current_user&.id || 'anonymous'} - IP: #{request.remote_ip}"
  end
  
  def log_api_response
    Rails.logger.info "API Response: #{response.status} - #{response.body.size} bytes"
  end
  
  # Standard rate limiting (override in subclasses)
  def check_rate_limit
    # Implement rate limiting logic here
    # Example: RateLimiter.check(current_user, request.path)
  end
  
  # Handle JSON parsing errors
  def handle_json_error(exception)
    Rails.logger.warn "JSON parsing error: #{exception.message} from IP #{request.remote_ip}"
    error_response('Invalid JSON format', ['Request body must be valid JSON'], :bad_request)
  end
  
  # Handle missing parameters
  def handle_parameter_missing(exception)
    Rails.logger.warn "Missing parameter: #{exception.param} from IP #{request.remote_ip}"
    error_response('Missing required parameter', ["Parameter '#{exception.param}' is required"], :bad_request)
  end
  
  # Handle unpermitted parameters
  def handle_unpermitted_parameters(exception)
    Rails.logger.warn "Unpermitted parameters: #{exception.params} from IP #{request.remote_ip}"
    error_response('Unpermitted parameters', ["Parameters '#{exception.params.join(', ')}' are not allowed"], :bad_request)
  end
  
  # Standard parameter handling
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
  
  # Standard pagination
  def paginate(collection, per_page = DEFAULT_PER_PAGE)
    page = params[:page]&.to_i || 1
    per_page = [per_page, MAX_PER_PAGE].min
    
    collection.page(page).per(per_page)
  end
  
  # Standard sorting
  def sort_collection(collection, default_sort = 'created_at DESC')
    sort_field = params[:sort] || default_sort.split(' ').first
    sort_direction = params[:direction] || default_sort.split(' ').last
    
    if collection.column_names.include?(sort_field)
      collection.order("#{sort_field} #{sort_direction}")
    else
      collection.order(default_sort)
    end
  end
  
  # Standard filtering
  def filter_collection(collection, allowed_filters = [])
    allowed_filters.each do |filter|
      if params[filter].present?
        collection = collection.where(filter => params[filter])
      end
    end
    
    collection
  end
  
  # Standard search
  def search_collection(collection, search_fields = [])
    return collection if params[:q].blank? || search_fields.empty?
    
    query = params[:q]
    conditions = search_fields.map { |field| "#{field} ILIKE ?" }.join(' OR ')
    
    collection.where(conditions, *search_fields.map { "%#{query}%" })
  end
  
  # Standard includes (for eager loading)
  def include_associations(collection, allowed_includes = [])
    includes = params[:include]&.split(',')&.map(&:strip) || []
    valid_includes = includes & allowed_includes
    
    valid_includes.any? ? collection.includes(*valid_includes) : collection
  end
  
  # Standard response formatting
  def format_collection_response(collection, serializer_class = nil, meta = {})
    data = serialize_collection(collection, serializer_class)
    
    success_response(
      data,
      'Collection retrieved successfully',
      :ok,
      meta.merge(pagination_meta(collection))
    )
  end
  
  def format_resource_response(resource, serializer_class = nil, message = 'Resource retrieved successfully')
    data = serialize_resource(resource, serializer_class)
    
    success_response(data, message)
  end
  
  def format_created_response(resource, serializer_class = nil, message = 'Resource created successfully')
    data = serialize_resource(resource, serializer_class)
    
    success_response(data, message, :created)
  end
  
  def format_updated_response(resource, serializer_class = nil, message = 'Resource updated successfully')
    data = serialize_resource(resource, serializer_class)
    
    success_response(data, message)
  end
  
  def format_deleted_response(message = 'Resource deleted successfully')
    success_response({}, message, :no_content)
  end
  
  # Standard error responses
  def format_validation_error(resource, message = 'Validation failed')
    error_response(message, resource.errors.full_messages, :unprocessable_entity)
  end
  
  def format_not_found_error(resource_name = 'Resource')
    error_response("#{resource_name} not found", [], :not_found)
  end
  
  def format_unauthorized_error(message = 'Unauthorized access')
    error_response(message, [], :unauthorized)
  end
  
  def format_forbidden_error(message = 'Access denied')
    error_response(message, [], :forbidden)
  end
  
  # Standard CRUD operations
  def index_action(collection, allowed_filters: [], allowed_includes: [], search_fields: [])
    collection = filter_collection(collection, allowed_filters)
    collection = search_collection(collection, search_fields)
    collection = include_associations(collection, allowed_includes)
    collection = sort_collection(collection)
    collection = paginate(collection)
    
    format_collection_response(collection)
  end
  
  def show_action(resource, allowed_includes: [])
    return format_not_found_error unless resource
    
    resource = include_associations(resource, allowed_includes)
    format_resource_response(resource)
  end
  
  def create_action(resource_class, params_method, serializer_class = nil)
    resource = resource_class.new(send(params_method))
    
    if resource.save
      format_created_response(resource, serializer_class)
    else
      format_validation_error(resource)
    end
  end
  
  def update_action(resource, params_method, serializer_class = nil)
    if resource.update(send(params_method))
      format_updated_response(resource, serializer_class)
    else
      format_validation_error(resource)
    end
  end
  
  def destroy_action(resource)
    if resource.destroy
      format_deleted_response
    else
      format_validation_error(resource, 'Failed to delete resource')
    end
  end
  
  # Standard authorization helpers
  def authorize_user!
    unless current_user
      format_unauthorized_error
      return false
    end
    
    true
  end
  
  def authorize_admin!
    unless current_user&.admin?
      format_forbidden_error('Admin access required')
      return false
    end
    
    true
  end
  
  def authorize_owner!(resource)
    unless current_user&.id == resource.user_id
      format_forbidden_error('Access denied to this resource')
      return false
    end
    
    true
  end
  
  # Standard cache helpers
  def cache_key_with_version(resource)
    "#{resource.cache_key}/#{resource.updated_at.to_i}"
  end
  
  def cache_response(key, expires_in: 1.hour)
    Rails.cache.fetch(key, expires_in: expires_in) do
      yield
    end
  end
  
  # Standard audit helpers
  def audit_action(action, resource = nil, details = {})
    AuditLog.create!(
      user: current_user,
      action: action,
      resource_type: resource&.class&.name,
      resource_id: resource&.id,
      details: details,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
