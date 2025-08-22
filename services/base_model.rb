# frozen_string_literal: true

# Base Model for all microservices
# This provides standardized validations, callbacks, and utility methods
class BaseModel < ApplicationRecord
  self.abstract_class = true

  # Standard validation messages
  VALIDATION_MESSAGES = {
    required: 'is required',
    invalid_format: 'has invalid format',
    already_exists: 'already exists',
    too_short: 'is too short',
    too_long: 'is too long',
    invalid_length: 'has invalid length',
    must_be_present: 'must be present',
    must_be_blank: 'must be blank',
    must_be_accepted: 'must be accepted',
    must_be_greater_than: 'must be greater than %{count}',
    must_be_less_than: 'must be less than %{count}',
    must_be_greater_than_or_equal_to: 'must be greater than or equal to %{count}',
    must_be_less_than_or_equal_to: 'must be less than or equal to %{count}',
    must_be_an_integer: 'must be an integer',
    must_be_greater_than_0: 'must be greater than 0',
    must_be_positive: 'must be positive',
    must_be_unique: 'must be unique',
    confirmation_does_not_match: "doesn't match confirmation",
    not_a_number: 'is not a number',
    not_an_integer: 'is not an integer',
    must_be_included_in: 'must be included in the list',
    must_be_excluded_from: 'must be excluded from the list',
    reserved: 'is reserved',
    taken: 'has already been taken',
    not_found: 'not found',
    invalid: 'is invalid',
    expired: 'has expired',
    too_many_requests: 'too many requests',
    rate_limited: 'rate limited'
  }.freeze

  # Standard callbacks
  before_create :set_default_values
  before_save :normalize_attributes
  before_validation :sanitize_attributes

  # Standard scopes
  scope :active, -> { where(status: 1) }
  scope :inactive, -> { where(status: 0) }
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }
  scope :updated_recently, -> { order(updated_at: :desc) }

  # Standard enums
  enum status: { inactive: 0, active: 1, pending: 2, suspended: 3 }
  enum role: { user: 0, admin: 1, moderator: 2 }

  # Standard validations
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :created_at, presence: true
  validates :updated_at, presence: true

  # Standard methods
  def active?
    status == 'active'
  end

  def inactive?
    status == 'inactive'
  end

  def pending?
    status == 'pending'
  end

  def suspended?
    status == 'suspended'
  end

  def admin?
    respond_to?(:role) && role == 'admin'
  end

  def user?
    respond_to?(:role) && role == 'user'
  end

  def moderator?
    respond_to?(:role) && role == 'moderator'
  end

  def display_name
    if respond_to?(:name) && name.present?
      name
    elsif respond_to?(:title) && title.present?
      title
    elsif respond_to?(:email) && email.present?
      email
    else
      "ID: #{id}"
    end
  end

  def to_s
    display_name
  end

  def created_today?
    created_at.to_date == Date.current
  end

  def updated_today?
    updated_at.to_date == Date.current
  end

  def age_in_days
    (Date.current - created_at.to_date).to_i
  end

  def age_in_hours
    ((Time.current - created_at) / 1.hour).round
  end

  def age_in_minutes
    ((Time.current - created_at) / 1.minute).round
  end

  # Serialization helpers
  def as_json(options = {})
    super(options).merge(
      'display_name' => display_name,
      'age_in_days' => age_in_days,
      'created_today' => created_today?,
      'updated_today' => updated_today?
    )
  end

  # Search helpers
  def self.search(query, fields = [])
    return all if query.blank?

    conditions = fields.map do |field|
      "#{field} ILIKE ?"
    end.join(' OR ')

    where(conditions, *fields.map { "%#{query}%" })
  end

  def self.filter_by_status(status)
    return all if status.blank?
    
    where(status: status)
  end

  def self.filter_by_date_range(start_date, end_date)
    return all if start_date.blank? && end_date.blank?

    query = all
    query = query.where('created_at >= ?', start_date.to_date.beginning_of_day) if start_date.present?
    query = query.where('created_at <= ?', end_date.to_date.end_of_day) if end_date.present?
    query
  end

  # Pagination helpers
  def self.paginate(page: 1, per_page: 20)
    page(page).per(per_page)
  end

  # Cache helpers
  def self.cached_find(id)
    Rails.cache.fetch("model:#{name}:#{id}", expires_in: 1.hour) do
      find(id)
    end
  end

  def cache_key_with_version
    "#{cache_key}/#{updated_at.to_i}"
  end

  # Validation helpers
  def self.valid_statuses
    statuses.keys
  end

  def self.valid_roles
    roles.keys
  end

  # Error handling
  def custom_errors
    errors.map do |error|
      {
        field: error.attribute,
        message: error.message,
        type: error.type
      }
    end
  end

  def has_errors?
    errors.any?
  end

  def error_messages
    errors.full_messages
  end

  # State management
  def activate!
    update!(status: :active)
  end

  def deactivate!
    update!(status: :inactive)
  end

  def suspend!
    update!(status: :suspended)
  end

  def make_pending!
    update!(status: :pending)
  end

  # Soft delete helpers
  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def soft_deleted?
    deleted_at.present?
  end

  # Audit helpers
  def audit_changes
    saved_changes.transform_values(&:last)
  end

  def audit_previous_changes
    saved_changes.transform_values(&:first)
  end

  private

  def set_default_values
    self.status ||= :active
    self.created_at ||= Time.current
    self.updated_at ||= Time.current
  end

  def normalize_attributes
    # Override in subclasses to normalize specific attributes
  end

  def sanitize_attributes
    # Override in subclasses to sanitize specific attributes
  end

  # Standard validation methods
  def validate_email_format(email)
    return true if email.blank?
    
    email_regex = URI::MailTo::EMAIL_REGEXP
    email.match?(email_regex)
  end

  def validate_phone_format(phone)
    return true if phone.blank?
    
    # Basic phone validation - override in subclasses for specific formats
    phone.match?(/\A\+?[\d\s\-\(\)]+\z/)
  end

  def validate_url_format(url)
    return true if url.blank?
    
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def validate_strong_password(password)
    return true if password.blank?
    
    # At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    password.match?(/\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}\z/)
  end
end
