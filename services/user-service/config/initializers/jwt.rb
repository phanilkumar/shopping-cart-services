# frozen_string_literal: true

# JWT Configuration
JWT_SECRET_KEY = Rails.application.credentials.secret_key_base
JWT_ALGORITHM = 'HS256'
JWT_EXPIRATION = 24.hours
JWT_REFRESH_EXPIRATION = 7.days

# JWT token structure
JWT_PAYLOAD_STRUCTURE = {
  user_id: nil,
  email: nil,
  exp: nil,
  iat: nil,
  jti: nil
}




