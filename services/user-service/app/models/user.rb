class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable

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
    payload = {
      user_id: id,
      email: email,
      exp: 24.hours.from_now.to_i
    }
    
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end

  def generate_refresh_token
    payload = {
      user_id: id,
      exp: 7.days.from_now.to_i,
      type: 'refresh'
    }
    
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end

  # Account lockout methods
  def access_locked?
    locked_at.present? && locked_at > 15.minutes.ago
  end

  def unlock_account!
    update(locked_at: nil, failed_attempts: 0)
  end

  def increment_failed_attempts!
    increment!(:failed_attempts)
    if failed_attempts >= Devise.maximum_attempts
      update(locked_at: Time.current)
    end
  end

  def reset_failed_attempts!
    update(failed_attempts: 0, locked_at: nil)
  end

  private

  def set_default_values
    self.status ||= 1
    self.role ||= 0
    self.failed_attempts ||= 0
  end

  def sanitize_phone
    return unless phone.present?
    
    # Remove all non-digit characters except +
    cleaned_phone = phone.gsub(/[^\d+]/, '')
    
    # If it starts with +91, keep it, otherwise add +91
    if cleaned_phone.start_with?('+91')
      self.phone = cleaned_phone
    elsif cleaned_phone.length == 10
      self.phone = "+91#{cleaned_phone}"
    else
      self.phone = cleaned_phone
    end
  end

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def password_complexity
    return if password.blank?
    
    # Check minimum length
    if password.length < 8
      errors.add(:password, 'must be at least 8 characters long')
    end
    
    # Check maximum length
    if password.length > 16
      errors.add(:password, 'must be at most 16 characters long')
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
      errors.add(:password, 'must contain at least one special character')
    end
  end

  def jwt_secret_key
    Rails.application.credentials.secret_key_base
  end
end
