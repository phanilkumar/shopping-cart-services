class User < ApplicationRecord
  has_secure_password
  
  # Callbacks
  before_create :set_default_values
  before_validation :sanitize_phone
  before_save :normalize_email
  before_create :set_default_password_for_phone

  # Basic validations
  validates :email, presence: { message: '%{attribute} is required' }, 
            uniqueness: { case_sensitive: false, message: '%{attribute} address is already registered' },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: 'Please enter a valid email address' }
  
  validates :password, presence: { message: '%{attribute} is required' }, 
            length: { minimum: 6, maximum: 6, message: '%{attribute} must be exactly 6 characters' }, 
            format: { with: /\A\d{6}\z/, message: '%{attribute} must be 6 digits' },
            on: :create
  
  validates :phone, presence: { message: '%{attribute} number is required' }, if: :phone_required?
  validates :phone, format: { with: /\A\+91[6-9]\d{9}\z/, message: 'Please enter a valid 10-digit mobile number' }, allow_blank: true
  validates :phone, uniqueness: { message: '%{attribute} number is already registered' }, allow_blank: true

  # Override to prevent duplicate attribute names in error messages
  def errors
    super.tap do |errors|
      def errors.full_messages
        map do |error|
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
          elsif message.match?(/^(Email|Phone|Password)/)
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

  def phone_required?
    email.blank?
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
        exp: 24.hours.from_now.to_i
      },
      Rails.application.credentials.secret_key_base,
      'HS256'
    )
  end

  def generate_refresh_token
    SecureRandom.hex(32)
  end

  private

  def set_default_values
    self.status ||= 1  # Set to active by default
    self.role ||= 0    # Set to user by default
  end

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def set_default_password_for_phone
    # If user has phone but no password, set a default 6-digit password
    if phone.present? && password.blank?
      self.password = '123456' # Default 6-digit password for phone users
      self.password_confirmation = '123456'
    end
  end

  def sanitize_phone
    return if phone.blank?
    
    # Remove any existing country code or special characters
    cleaned_phone = phone.to_s.gsub(/[^\d]/, '')
    
    # If it's a 10-digit number starting with 6-9, add +91 prefix
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
end
