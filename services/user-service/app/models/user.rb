class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :trackable, :timeoutable

  # Audit logging with sensitive data exclusion
  # audited except: [:password, :encrypted_password, :reset_password_token, :unlock_token, :confirmation_token, :two_factor_secret]

  # Callbacks
  before_create :set_default_values
  before_validation :sanitize_phone
  before_save :normalize_email

  # Email validation is handled by Devise :validatable module
  # Additional email length validation
  validates :email, length: { maximum: 50, message: 'Email address is too long (maximum 50 characters)' }
  
  # First name validation
  validates :first_name, presence: { message: 'First name is required' },
            length: { minimum: 4, maximum: 20, message: 'First name must be between 4 and 20 characters' },
            format: { 
              with: /\A[a-zA-Z]+\z/, 
              message: 'First name can only contain letters (a-z, A-Z)' 
            }
  
  # Last name validation
  validates :last_name, presence: { message: 'Last name is required' },
            length: { minimum: 4, maximum: 20, message: 'Last name must be between 4 and 20 characters' },
            format: { 
              with: /\A[a-zA-Z]+\z/, 
              message: 'Last name can only contain letters (a-z, A-Z)' 
            }
  
  # Indian mobile number validation (10 digits starting with 6, 7, 8, or 9)
  validates :phone, presence: { message: 'Mobile number is required' }
  validates :phone, format: { 
              with: /\A\+?91[6-9]\d{9}\z/, 
              message: 'Please enter a valid 10-digit Indian mobile number (e.g., 9876543210)' 
            }, allow_blank: true
  validates :phone, uniqueness: { message: 'Mobile number is already registered' }, allow_blank: true

  # Password validation (custom validation for Devise)
  validate :password_complexity
  validate :password_not_common

  # Two-factor authentication fields
  attr_accessor :otp_code
  validates :two_factor_secret, presence: true, if: :two_factor_enabled?

  # Override to prevent duplicate attribute names in error messages
  def errors
    super.tap do |errors|
      def errors.full_messages
        # Get all error messages
        all_messages = map do |error|
          attribute = error.attribute.to_s.humanize
          message = error.message
          
          # Handle interpolation and prevent duplication
          if message.include?('%{attribute}')
            # Replace %{attribute} with the actual attribute name
            interpolated_message = message.gsub('%{attribute}', attribute)
            # If it would create duplication, just use the message part
            if interpolated_message.downcase.start_with?(attribute.downcase)
              interpolated_message
            else
              interpolated_message
            end
          elsif message.match?(/^(Email|Phone|Password|First name|Last name)/)
            # If message already starts with attribute name, use as-is
            message
          elsif message.match?(/^Please enter a valid/)
            # For format validation messages that start with "Please enter"
            message
          else
            # Default Rails behavior for other cases
            "#{attribute} #{message}"
          end
        end
        
        # Filter out duplicate email errors - keep only the first one
        email_errors = all_messages.select { |msg| msg.downcase.include?('email') && msg.downcase.include?('already') }
        other_errors = all_messages.reject { |msg| msg.downcase.include?('email') && msg.downcase.include?('already') }
        
        if email_errors.any?
          # Use the first email error and add other errors
          [email_errors.first] + other_errors
        else
          all_messages
        end
      end
    end
  end

  # Instance methods
  def display_name
    [first_name, last_name].compact.join(' ').presence || email
  end

  def full_name
    [first_name, last_name].compact.join(' ')
  end

  def admin?
    role == 1
  end

  def active?
    status == 1
  end

  def update_last_login
    update(last_login_at: Time.current)
  end

  def generate_jwt_token
    JWT.encode(
      {
        user_id: id,
        email: email,
        exp: 24.hours.from_now.to_i,
        jti: SecureRandom.uuid
      },
      jwt_secret_key,
      'HS256'
    )
  end
  
  def generate_refresh_token
    SecureRandom.hex(32)
  end
  
  private
  
  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key'
  end
  
  public
  
  # Two-factor authentication methods
  def enable_two_factor!
    update!(
      two_factor_secret: ROTP::Base32.random,
      two_factor_enabled: true
    )
  end

  def disable_two_factor!
    update!(
      two_factor_secret: nil,
      two_factor_enabled: false
    )
  end

  def two_factor_qr_code
    return nil unless two_factor_secret.present?
    
    totp = ROTP::TOTP.new(two_factor_secret, issuer: 'User Service')
    totp.provisioning_uri(email)
  end

  def verify_otp(code)
    return false unless two_factor_secret.present?
    
    totp = ROTP::TOTP.new(two_factor_secret)
    totp.verify(code, drift_behind: 30)
  end

  # Security methods
  def lock_account!
    update!(locked_at: Time.current)
    AuditLog.log_account_locked(self, Current.request) if Current.request
    Rails.logger.warn "Account locked for user #{id} (#{email})"
  end

  def unlock_account!
    update!(locked_at: nil, failed_attempts: 0)
    AuditLog.log_account_unlocked(self, Current.request) if Current.request
    Rails.logger.info "Account unlocked for user #{id} (#{email})"
  end

  def account_locked?
    locked_at.present?
  end

  def increment_failed_attempts!
    new_attempts = (failed_attempts || 0) + 1
    update!(failed_attempts: new_attempts)
    
    # Lock account after 5 failed attempts
    if new_attempts >= 5
      lock_account!
    end
  end

  def reset_failed_attempts!
    update!(failed_attempts: 0)
  end

  # Password security
  def password_compromised?
    return false unless password.present?
    
    # Check against common passwords
    common_passwords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey'
    ]
    
    common_passwords.include?(password.downcase)
  end

  private

  def set_default_values
    self.status ||= 1  # Set to active by default
    self.role ||= 0    # Set to user by default
    self.failed_attempts ||= 0
    self.two_factor_enabled ||= false
  end
  
  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key'
  end

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def sanitize_phone
    return if phone.blank?
    
    # Remove any existing country code or special characters
    cleaned_phone = phone.to_s.gsub(/[^\d]/, '')
    
    # If it's a 10-digit number starting with 6, 7, 8, or 9, assume it's an Indian number and add +91 prefix
    if cleaned_phone.match?(/\A[6-9]\d{9}\z/)
      self.phone = "+91#{cleaned_phone}"
    elsif cleaned_phone.match?(/\A91[6-9]\d{9}\z/)
      # If it already has 91 prefix, add + sign
      self.phone = "+#{cleaned_phone}"
    elsif cleaned_phone.match?(/\A\+91[6-9]\d{9}\z/)
      # If it already has +91 prefix, keep as is
      self.phone = cleaned_phone
    end
  end

  def password_complexity
    return if password.blank?
    
    # Check minimum and maximum length
    if password.length < 8
      errors.add(:password, 'must be at least 8 characters long')
    elsif password.length > 16
      errors.add(:password, 'must not exceed 16 characters')
    end
    
    # Check for at least one letter
    unless password.match?(/[a-zA-Z]/)
      errors.add(:password, 'must contain at least one letter')
    end
    
    # Check for at least one number
    unless password.match?(/\d/)
      errors.add(:password, 'must contain at least one number')
    end
    
    # Check for at least one special character
    unless password.match?(/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/)
      errors.add(:password, 'must contain at least one special character (!@#$%^&*()_+-=[]{}|;:,.<>?)')
    end
    
    # Check for only allowed characters
    unless password.match?(/\A[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+\z/)
      errors.add(:password, 'can only contain letters, numbers, and special characters')
    end
  end

  def password_not_common
    return if password.blank?
    
    if password_compromised?
      errors.add(:password, 'is too common. Please choose a more secure password.')
    end
  end

  def log_failed_login
    Rails.logger.warn "Failed login attempt for user #{id} (#{email}) from IP: #{Current.request&.remote_ip}"
    
    # You could also send this to your monitoring service
    # Sentry.capture_message("Failed login attempt", level: :warning, extra: { user_id: id, email: email, ip: Current.request&.remote_ip }) if defined?(Sentry)
  end

  def log_successful_login
    Rails.logger.info "Successful login for user #{id} (#{email}) from IP: #{Current.request&.remote_ip}"
    update_last_login
  end
end
