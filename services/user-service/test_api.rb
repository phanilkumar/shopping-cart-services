#!/usr/bin/env ruby

# Simple API test script for the user service
require 'net/http'
require 'json'
require 'uri'

# Configuration
BASE_URL = 'http://localhost:3001'
API_BASE = "#{BASE_URL}/api/v1"

def make_request(method, endpoint, data = nil, headers = {})
  uri = URI("#{API_BASE}#{endpoint}")
  
  case method.upcase
  when 'GET'
    request = Net::HTTP::Get.new(uri)
  when 'POST'
    request = Net::HTTP::Post.new(uri)
  when 'PUT'
    request = Net::HTTP::Put.new(uri)
  when 'DELETE'
    request = Net::HTTP::Delete.new(uri)
  end
  
  # Set headers
  headers.each { |key, value| request[key] = value }
  request['Content-Type'] = 'application/json' unless headers['Content-Type']
  
  # Set body for POST/PUT requests
  if data && ['POST', 'PUT'].include?(method.upcase)
    request.body = data.to_json
  end
  
  # Make request
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  return response
rescue => e
  puts "Error making request: #{e.message}"
  return nil
end

def print_response(response, test_name)
  puts "\n" + "="*50
  puts "TEST: #{test_name}"
  puts "="*50
  puts "Status: #{response.code} #{response.message}"
  puts "Headers: #{response.to_hash}"
  
  begin
    body = JSON.parse(response.body)
    puts "Response: #{JSON.pretty_generate(body)}"
  rescue JSON::ParserError
    puts "Response: #{response.body}"
  end
end

# Test data
test_credentials = {
  admin: { email: 'admin@example.com', password: 'admin123' },
  regular: { email: 'john.doe@example.com', password: 'password123' },
  otp_test: { email: 'otptest@example.com', password: 'password123' },
  inactive: { email: 'inactive@example.com', password: 'password123' }
}

puts "Starting API tests for User Service..."
puts "Base URL: #{BASE_URL}"
puts "API Base: #{API_BASE}"

# Test 1: Health check (if available)
puts "\n1. Testing basic connectivity..."
response = make_request('GET', '/health', nil, { 'Accept' => 'application/json' })
if response
  print_response(response, "Health Check")
else
  puts "Could not connect to the service. Make sure it's running on #{BASE_URL}"
end

# Test 1.5: Test web registration page
puts "\n1.5. Testing web registration page..."
begin
  require 'net/http'
  uri = URI("#{BASE_URL}/register")
  response = Net::HTTP.get_response(uri)
  puts "Registration page status: #{response.code} #{response.message}"
  if response.code == '200'
    puts "✅ Registration page is accessible"
  else
    puts "❌ Registration page returned #{response.code}"
  end
rescue => e
  puts "❌ Could not access registration page: #{e.message}"
end

# Test 2: Login with admin user
puts "\n2. Testing admin login..."
login_data = {
  user: {
    email: test_credentials[:admin][:email],
    password: test_credentials[:admin][:password]
  }
}
response = make_request('POST', '/auth/login', login_data)
print_response(response, "Admin Login")

# Extract token if login successful
token = nil
if response&.code == '200'
  begin
    body = JSON.parse(response.body)
    token = body['token'] || body['jwt']
  rescue JSON::ParserError
    puts "Could not parse response for token"
  end
end

# Test 3: Login with regular user
puts "\n3. Testing regular user login..."
login_data = {
  user: {
    email: test_credentials[:regular][:email],
    password: test_credentials[:regular][:password]
  }
}
response = make_request('POST', '/auth/login', login_data)
print_response(response, "Regular User Login")

# Test 4: Login with inactive user
puts "\n4. Testing inactive user login..."
login_data = {
  user: {
    email: test_credentials[:inactive][:email],
    password: test_credentials[:inactive][:password]
  }
}
response = make_request('POST', '/auth/login', login_data)
print_response(response, "Inactive User Login")

# Test 5: Get user profile (if we have a token)
if token
  puts "\n5. Testing get user profile..."
  headers = { 'Authorization' => "Bearer #{token}" }
  response = make_request('GET', '/users/profile', nil, headers)
  print_response(response, "Get User Profile")
end

# Test 6: Send OTP
puts "\n6. Testing OTP send..."
otp_data = { phone: '+919876543218' }  # OTP test user's phone
response = make_request('POST', '/auth/otp/send', otp_data)
print_response(response, "Send OTP")

# Test 7: Verify OTP (with dummy OTP)
puts "\n7. Testing OTP verification..."
otp_verify_data = { 
  phone: '+919876543218',
  otp: '123456'  # Dummy OTP
}
response = make_request('POST', '/auth/otp/verify', otp_verify_data)
print_response(response, "Verify OTP")

# Test 8: Get specific user (if we have a token)
if token
  puts "\n8. Testing get specific user..."
  headers = { 'Authorization' => "Bearer #{token}" }
  response = make_request('GET', '/users/1', nil, headers)
  print_response(response, "Get Specific User")
end

# Test 9: Logout (if we have a token)
if token
  puts "\n9. Testing logout..."
  headers = { 'Authorization' => "Bearer #{token}" }
  response = make_request('DELETE', '/auth/logout', nil, headers)
  print_response(response, "Logout")
end

# Test 10: Test web logout
puts "\n10. Testing web logout..."
begin
  uri = URI("#{BASE_URL}/logout")
  response = Net::HTTP.get_response(uri)
  puts "Web logout status: #{response.code} #{response.message}"
  if response.code == '302'
    puts "✅ Web logout redirects to: #{response['location']}"
  else
    puts "❌ Web logout returned #{response.code}"
  end
rescue => e
  puts "❌ Could not access web logout: #{e.message}"
end

# Test 11: Test congratulations page
puts "\n11. Testing congratulations page..."
begin
  uri = URI("#{BASE_URL}/congratulations")
  response = Net::HTTP.get_response(uri)
  puts "Congratulations page status: #{response.code} #{response.message}"
  if response.code == '302'
    puts "✅ Congratulations page redirects to: #{response['location']}"
  else
    puts "❌ Congratulations page returned #{response.code}"
  end
rescue => e
  puts "❌ Could not access congratulations page: #{e.message}"
end

puts "\n" + "="*50
puts "API TESTS COMPLETED"
puts "="*50
puts "\nNote: Some tests may fail if the service is not running or if endpoints"
puts "are not implemented yet. This is expected during development."
