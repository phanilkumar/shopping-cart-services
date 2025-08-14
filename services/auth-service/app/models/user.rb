class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Validations
  validates :email, presence: true, uniqueness: true, email_format: true
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :phone, presence: true, format: { with: /\A\+?[\d\s\-\(\)]+\z/ }
  validates :password, length: { minimum: 8 }, if: :password_required?
  validates :password_confirmation, presence: true, if: :password_required?
  
  # Enums
  enum status: { active: 0, inactive: 1, suspended: 2 }
  enum role: { customer: 0, admin: 1, moderator: 2 }
  
  # Scopes
  scope :active, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_email, ->(email) { where('LOWER(email) = ?', email.downcase) }
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def display_name
    full_name.presence || email
  end
  
  def active_for_authentication?
    super && active?
  end
  
  def inactive_message
    if suspended?
      :suspended
    else
      super
    end
  end
  
  def generate_jwt_token
    payload = {
      user_id: id,
      email: email,
      exp: 1.hour.from_now.to_i,
      iat: Time.current.to_i
    }
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end
  
  def generate_refresh_token
    payload = {
      user_id: id,
      exp: 7.days.from_now.to_i,
      iat: Time.current.to_i,
      type: 'refresh'
    }
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end
  
  def update_last_login
    update(last_login_at: Time.current)
  end
  
  def send_password_reset_email
    token = generate_password_reset_token
    # In a real implementation, you would send an email here
    # UserMailer.password_reset(self, token).deliver_later
  end
  
  def password_reset_token_valid?(token)
    password_reset_token == token && 
    password_reset_sent_at.present? && 
    password_reset_sent_at > 1.hour.ago
  end
  
  private
  
  def generate_password_reset_token
    token = SecureRandom.hex(32)
    update(
      password_reset_token: token,
      password_reset_sent_at: Time.current
    )
    token
  end
  
  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key'
  end
  
  def password_required?
    new_record? || password.present? || password_confirmation.present?
  end
end
