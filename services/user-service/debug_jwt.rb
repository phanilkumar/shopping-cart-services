#!/usr/bin/env ruby

require_relative 'config/environment'

# Test JWT token generation and decoding
puts "Testing JWT functionality..."

# Create a test user
user = User.find_by(email: 'test_jwt@example.com')
if user.nil?
  puts "Creating test user..."
  user = User.create!(
    email: 'test_jwt@example.com',
    password: 'SecurePass123!',
    password_confirmation: 'SecurePass123!',
    first_name: 'Test',
    last_name: 'User',
    phone: '+919876543999'
  )
end

puts "User ID: #{user.id}"

# Generate tokens
puts "Generating tokens..."
jwt_token = user.generate_jwt_token
refresh_token = user.generate_refresh_token

puts "JWT Token: #{jwt_token}"
puts "Refresh Token: #{refresh_token}"

# Decode tokens
puts "\nDecoding tokens..."
begin
  decoded_jwt = JWT.decode(jwt_token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
  puts "JWT Token decoded successfully: #{decoded_jwt[0]}"
rescue => e
  puts "JWT Token decode failed: #{e.message}"
end

begin
  decoded_refresh = JWT.decode(refresh_token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
  puts "Refresh Token decoded successfully: #{decoded_refresh[0]}"
rescue => e
  puts "Refresh Token decode failed: #{e.message}"
end

# Test with the specific token from the test
puts "\nTesting with specific token from test..."
specific_token = "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxOCwiZXhwIjoxNzU3MDk1NTA5LCJ0eXBlIjoicmVmcmVzaCJ9.niZ0-mHeRqoEKimtmaVuDVKwQ5TSV6Wub8VXaQcqRIk"

begin
  decoded_specific = JWT.decode(specific_token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
  puts "Specific token decoded successfully: #{decoded_specific[0]}"
  
  # Check if user exists
  user_id = decoded_specific[0]['user_id']
  found_user = User.find_by(id: user_id)
  puts "User found: #{found_user ? 'Yes' : 'No'}"
  puts "User ID in token: #{user_id}"
  puts "User ID in database: #{found_user&.id}"
  
rescue => e
  puts "Specific token decode failed: #{e.message}"
  puts "Error class: #{e.class}"
end

puts "\nJWT Secret Key: #{Rails.application.credentials.secret_key_base[0..20]}..."
