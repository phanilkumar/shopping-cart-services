class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Callbacks
  before_create :set_default_values

  # Basic validations for existing fields
  validates :email, presence: true, uniqueness: true
  validates :phone, presence: true, if: :phone_required?
  validates :phone, format: { with: /\A\+91[6-9]\d{9}\z/ }, allow_blank: true

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
end
