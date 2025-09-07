class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  
  # Validations
  validates :action, presence: true
  
  # Scopes
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_resource, ->(resource_type, resource_id) { where(resource_type: resource_type, resource_id: resource_id) }
  scope :by_ip, ->(ip) { where(ip_address: ip) }
  scope :recent, ->(days = 30) { where('created_at >= ?', days.days.ago) }
  scope :login_events, -> { where(action: ['login_success', 'login_failure', 'logout']) }
  scope :security_events, -> { where(action: ['account_locked', 'account_unlocked', 'password_changed', 'two_factor_enabled', 'two_factor_disabled']) }
  
  # Serialization - JSON columns are automatically serialized in Rails 7+
  
  # Instance methods
  def resource
    return nil unless resource_type && resource_id
    resource_type.constantize.find_by(id: resource_id)
  rescue NameError
    nil
  end
  
  def user_email
    user&.email || 'Anonymous'
  end
  
  def formatted_details
    details.map { |key, value| "#{key}: #{value}" }.join(', ')
  end
  
  def is_security_event?
    security_events = ['login_success', 'login_failure', 'logout', 'account_locked', 
                      'account_unlocked', 'password_changed', 'two_factor_enabled', 
                      'two_factor_disabled', 'registration']
    security_events.include?(action)
  end
  
  def is_sensitive_action?
    sensitive_actions = ['password_changed', 'two_factor_enabled', 'two_factor_disabled', 
                        'account_locked', 'account_unlocked']
    sensitive_actions.include?(action)
  end
  
  # Class methods for creating audit logs
  def self.log_login_success(user, request)
    create!(
      user: user,
      action: 'login_success',
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: request.session.id,
      request_id: request.request_id,
      details: {
        email: user.email,
        user_id: user.id,
        timestamp: Time.current
      }
    )
  end
  
  def self.log_login_failure(email, request, reason = 'invalid_credentials')
    create!(
      user: nil,
      action: 'login_failure',
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: request.session.id,
      request_id: request.request_id,
      details: {
        email: email,
        reason: reason,
        timestamp: Time.current
      }
    )
  end
  
  def self.log_account_locked(user, request)
    create!(
      user: user,
      action: 'account_locked',
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: request.session.id,
      request_id: request.request_id,
      details: {
        email: user.email,
        user_id: user.id,
        failed_attempts: user.failed_attempts,
        locked_at: user.locked_at,
        timestamp: Time.current
      }
    )
  end
  
  def self.log_account_unlocked(user, request)
    create!(
      user: user,
      action: 'account_unlocked',
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: request.session.id,
      request_id: request.request_id,
      details: {
        email: user.email,
        user_id: user.id,
        unlocked_at: Time.current,
        timestamp: Time.current
      }
    )
  end

  def self.log_account_auto_unlocked(user, request)
    create!(
      user: user,
      action: 'account_auto_unlocked',
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent,
      session_id: request&.session&.id,
      request_id: request&.request_id,
      details: {
        email: user.email,
        user_id: user.id,
        auto_unlocked_at: Time.current,
        timestamp: Time.current
      }
    )
  end
  
  def self.log_registration(user, request)
    create!(
      user: user,
      action: 'registration',
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: request.session.id,
      request_id: request.request_id,
      details: {
        email: user.email,
        user_id: user.id,
        registration_method: 'email',
        timestamp: Time.current
      }
    )
  end
  
  def self.log_logout(user, request)
    create!(
      user: user,
      action: 'logout',
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: request.session.id,
      request_id: request.request_id,
      details: {
        email: user.email,
        user_id: user.id,
        timestamp: Time.current
      }
    )
  end
  
  def self.log_password_change(user, request)
    create!(
      user: user,
      action: 'password_changed',
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: request.session.id,
      request_id: request.request_id,
      details: {
        email: user.email,
        user_id: user.id,
        changed_at: Time.current,
        timestamp: Time.current
      }
    )
  end
  
  def self.log_two_factor_toggle(user, request, enabled)
    action = enabled ? 'two_factor_enabled' : 'two_factor_disabled'
    create!(
      user: user,
      action: action,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: request.session.id,
      request_id: request.request_id,
      details: {
        email: user.email,
        user_id: user.id,
        enabled: enabled,
        timestamp: Time.current
      }
    )
  end
end



