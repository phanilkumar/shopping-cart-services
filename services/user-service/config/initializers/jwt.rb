# frozen_string_literal: true

# JWT Configuration
JWT_SECRET_KEY = ENV['JWT_SECRET_KEY'] || Rails.application.credentials.secret_key_base

# JWT token expiration times
JWT_ACCESS_TOKEN_EXPIRY = 24.hours
JWT_REFRESH_TOKEN_EXPIRY = 30.days

# JWT algorithm
JWT_ALGORITHM = 'HS256'

# JWT issuer and audience for additional security
JWT_ISSUER = ENV['JWT_ISSUER'] || 'user-service'
JWT_AUDIENCE = ENV['JWT_AUDIENCE'] || 'shopping-cart-app'




