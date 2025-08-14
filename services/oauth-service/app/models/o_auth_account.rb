class OAuthAccount < ApplicationRecord
  belongs_to :user
  
  # Validations
  validates :provider, presence: true, inclusion: { in: %w[google facebook github twitter linkedin] }
  validates :provider_uid, presence: true
  validates :provider_uid, uniqueness: { scope: :provider }
  
  # Scopes
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  
  # Instance methods
  def expired?
    expires_at.present? && expires_at < Time.current
  end
  
  def active?
    !expired?
  end
  
  def refresh_token_if_needed
    return unless expired? && refresh_token.present?
    
    # In a real implementation, you would refresh the token here
    # This would involve making a request to the OAuth provider
    # and updating the access_token and expires_at
  end
  
  def provider_name
    provider.titleize
  end
  
  def provider_icon
    case provider
    when 'google'
      'fab fa-google'
    when 'facebook'
      'fab fa-facebook'
    when 'github'
      'fab fa-github'
    when 'twitter'
      'fab fa-twitter'
    when 'linkedin'
      'fab fa-linkedin'
    else
      'fas fa-user'
    end
  end
  
  def self.find_or_create_from_oauth(auth_data, user = nil)
    oauth_account = find_by(provider: auth_data[:provider], provider_uid: auth_data[:provider_uid])
    
    if oauth_account
      oauth_account.update!(
        access_token: auth_data[:access_token],
        refresh_token: auth_data[:refresh_token],
        expires_at: auth_data[:expires_at]
      )
    else
      oauth_account = create!(
        user: user,
        provider: auth_data[:provider],
        provider_uid: auth_data[:provider_uid],
        access_token: auth_data[:access_token],
        refresh_token: auth_data[:refresh_token],
        expires_at: auth_data[:expires_at]
      )
    end
    
    oauth_account
  end
end
