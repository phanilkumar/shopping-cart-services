class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable

  # Override Devise validations with custom messages
  validates :email, presence: { message: 'Email is required' }, 
            uniqueness: { message: 'Email address is already registered' },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: 'Please enter a valid email address' }
  
  validates :password, presence: { message: 'Password is required' }, 
            length: { minimum: 6, message: 'Password must be at least 6 characters' }, 
            on: :create
  
  validates :phone, presence: { message: 'Phone number is required' }, if: :phone_required?
  validates :phone, format: { with: /\A\+91[6-9]\d{9}\z/, message: 'Please enter a valid 10-digit mobile number' }, allow_blank: true
  validates :phone, uniqueness: { message: 'Phone number is already registered' }, allow_blank: true

  # GST number validation (for business accounts)
  validates :gst_number, format: { 
    with: /\A\d{2}[A-Z]{5}\d{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}\z/ 
  }, allow_blank: true
  
  # PAN card validation
  validates :pan_number, format: { 
    with: /\A[A-Z]{5}[0-9]{4}[A-Z]{1}\z/ 
  }, allow_blank: true
  
  # Aadhaar validation (optional)
  validates :aadhaar_number, format: { 
    with: /\A\d{12}\z/ 
  }, allow_blank: true

  # Address validations
  validates :pincode, format: { with: /\A\d{6}\z/ }, allow_blank: true
  validates :state, inclusion: { in: INDIAN_STATES }, allow_blank: true

  # Enums
  enum user_type: { individual: 0, business: 1 }
  enum verification_status: { pending: 0, verified: 1, rejected: 2 }

  # Callbacks
  before_save :normalize_phone_number
  before_save :normalize_gst_number
  before_save :normalize_pan_number

  # Scopes
  scope :verified_users, -> { where(phone_verified: true, email_verified: true) }
  scope :business_users, -> { where(user_type: :business) }
  scope :by_state, ->(state) { where(state: state) }
  scope :by_city, ->(city) { where(city: city) }

  # Instance methods
  def full_address
    [address_line1, address_line2, city, state, pincode].compact.join(', ')
  end

  def display_name
    name.presence || email.presence || phone.presence || 'User'
  end

  def masked_phone
    return nil unless phone
    phone.gsub(/(\+91)(\d{3})(\d{3})(\d{4})/, '\1***\3\4')
  end

  def masked_pan
    return nil unless pan_number
    pan_number.gsub(/(\w{5})(\w{4})(\w{1})/, '\1***\3')
  end

  def masked_aadhaar
    return nil unless aadhaar_number
    aadhaar_number.gsub(/(\d{4})(\d{4})(\d{4})/, '\1****\3')
  end

  def is_business?
    user_type == 'business'
  end

  def requires_gst?
    is_business? && total_transactions > 2000000 # 20 lakhs threshold
  end

  def can_use_cod?
    phone_verified? && verification_status == 'verified'
  end

  def cod_limit
    case verification_status
    when 'verified'
      50000 # 50k for verified users
    when 'pending'
      10000 # 10k for pending users
    else
      0 # No COD for rejected users
    end
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

  def admin?
    role == 1
  end

  def active?
    status == 1
  end

  private

  def phone_required?
    email.blank?
  end

  def email_required?
    phone.blank?
  end

  def normalize_phone_number
    return unless phone.present?
    
    # Remove all non-digit characters
    phone.gsub!(/\D/, '')
    
    # Add +91 if not present
    if phone.length == 10
      self.phone = "+91#{phone}"
    elsif phone.length == 12 && phone.start_with?('91')
      self.phone = "+#{phone}"
    end
  end

  def normalize_gst_number
    return unless gst_number.present?
    self.gst_number = gst_number.upcase
  end

  def normalize_pan_number
    return unless pan_number.present?
    self.pan_number = pan_number.upcase
  end

  # Indian states list
  INDIAN_STATES = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Jammu and Kashmir', 'Ladakh',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Lakshadweep', 'Puducherry'
  ].freeze
end
