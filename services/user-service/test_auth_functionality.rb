#!/usr/bin/env ruby

# Comprehensive Authentication Functionality Test Script
# This script tests all login and registration functionalities

require 'net/http'
require 'json'
require 'uri'

class AuthFunctionalityTest
  BASE_URL = 'http://localhost:3001'
  
  def initialize
    @test_results = []
    @session_cookies = {}
  end
  
  def run_all_tests
    puts "🔍 Starting Comprehensive Authentication Functionality Test"
    puts "=" * 60
    
    test_health_check
    test_registration_flow
    test_login_flow
    test_otp_flow
    test_security_features
    test_api_endpoints
    test_error_handling
    
    print_results
  end
  
  private
  
  def test_health_check
    puts "\n📋 Testing Health Check..."
    
    response = make_request('GET', '/health')
    
    if response.code == '200'
      log_test('Health Check', 'PASS', 'Application is running')
    else
      log_test('Health Check', 'FAIL', "Expected 200, got #{response.code}")
    end
  end
  
  def test_registration_flow
    puts "\n📝 Testing Registration Flow..."
    
    # Test registration page accessibility
    response = make_request('GET', '/users/sign_up')
    if response.code == '200'
      log_test('Registration Page Access', 'PASS', 'Registration page is accessible')
    else
      log_test('Registration Page Access', 'FAIL', "Expected 200, got #{response.code}")
    end
    
    # Test registration with valid data
    test_user = {
      email: "test#{Time.now.to_i}@example.com",
      password: "TestPass123!",
      password_confirmation: "TestPass123!",
      first_name: "Test",
      last_name: "User",
      phone: "9876543210"
    }
    
    response = make_request('POST', '/users', test_user)
    
    if response.code == '200' || response.code == '201'
      log_test('User Registration', 'PASS', 'User registered successfully')
      @test_user = test_user
    else
      log_test('User Registration', 'FAIL', "Expected 200/201, got #{response.code}")
    end
  end
  
  def test_login_flow
    puts "\n🔐 Testing Login Flow..."
    
    return unless @test_user
    
    # Test login page accessibility
    response = make_request('GET', '/users/sign_in')
    if response.code == '200'
      log_test('Login Page Access', 'PASS', 'Login page is accessible')
    else
      log_test('Login Page Access', 'FAIL', "Expected 200, got #{response.code}")
    end
    
    # Test login with valid credentials
    login_data = {
      user: {
        email: @test_user[:email],
        password: @test_user[:password]
      }
    }
    
    response = make_request('POST', '/users/sign_in', login_data)
    
    if response.code == '200'
      log_test('User Login', 'PASS', 'User logged in successfully')
    else
      log_test('User Login', 'FAIL', "Expected 200, got #{response.code}")
    end
  end
  
  def test_otp_flow
    puts "\n📱 Testing OTP Flow..."
    
    # Test OTP send
    otp_data = { phone: "9876543210" }
    response = make_api_request('POST', '/api/v1/auth/otp/send', otp_data)
    
    if response.code == '200'
      log_test('OTP Send', 'PASS', 'OTP sent successfully')
      
      # Test OTP verification
      verify_data = { phone: "9876543210", otp: "123456" }
      response = make_api_request('POST', '/api/v1/auth/otp/verify', verify_data)
      
      if response.code == '200'
        log_test('OTP Verification', 'PASS', 'OTP verified successfully')
      else
        log_test('OTP Verification', 'FAIL', "Expected 200, got #{response.code}")
      end
    else
      log_test('OTP Send', 'FAIL', "Expected 200, got #{response.code}")
    end
  end
  
  def test_security_features
    puts "\n🛡️ Testing Security Features..."
    
    # Test rate limiting
    test_rate_limiting
    
    # Test password complexity
    test_password_complexity
    
    # Test input validation
    test_input_validation
  end
  
  def test_rate_limiting
    puts "  Testing Rate Limiting..."
    
    # Try multiple rapid login attempts
    6.times do |i|
      login_data = {
        user: {
          email: "test#{i}@example.com",
          password: "wrongpassword"
        }
      }
      
      response = make_request('POST', '/users/sign_in', login_data)
      
      if i < 5
        if response.code == '401'
          log_test("Rate Limiting - Attempt #{i+1}", 'PASS', 'Properly rejected invalid login')
        else
          log_test("Rate Limiting - Attempt #{i+1}", 'FAIL', "Expected 401, got #{response.code}")
        end
      else
        if response.code == '429'
          log_test("Rate Limiting - Blocked", 'PASS', 'Rate limiting working correctly')
        else
          log_test("Rate Limiting - Blocked", 'FAIL', "Expected 429, got #{response.code}")
        end
      end
    end
  end
  
  def test_password_complexity
    puts "  Testing Password Complexity..."
    
    weak_passwords = [
      "123",           # Too short
      "password",      # No numbers/special chars
      "password123",   # No special chars
      "PASSWORD123!",  # No lowercase
      "pass123",       # Too short
    ]
    
    weak_passwords.each_with_index do |password, i|
      registration_data = {
        user: {
          email: "test#{Time.now.to_i}#{i}@example.com",
          password: password,
          password_confirmation: password,
          first_name: "Test",
          last_name: "User",
          phone: "9876543210"
        }
      }
      
      response = make_request('POST', '/users', registration_data)
      
      if response.code == '422'
        log_test("Password Complexity - Weak Password #{i+1}", 'PASS', 'Weak password properly rejected')
      else
        log_test("Password Complexity - Weak Password #{i+1}", 'FAIL', "Expected 422, got #{response.code}")
      end
    end
  end
  
  def test_input_validation
    puts "  Testing Input Validation..."
    
    # Test invalid email
    invalid_email_data = {
      user: {
        email: "invalid-email",
        password: "TestPass123!",
        password_confirmation: "TestPass123!",
        first_name: "Test",
        last_name: "User",
        phone: "9876543210"
      }
    }
    
    response = make_request('POST', '/users', invalid_email_data)
    
    if response.code == '422'
      log_test('Input Validation - Invalid Email', 'PASS', 'Invalid email properly rejected')
    else
      log_test('Input Validation - Invalid Email', 'FAIL', "Expected 422, got #{response.code}")
    end
    
    # Test invalid phone
    invalid_phone_data = {
      user: {
        email: "test#{Time.now.to_i}@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!",
        first_name: "Test",
        last_name: "User",
        phone: "123"  # Invalid phone
      }
    }
    
    response = make_request('POST', '/users', invalid_phone_data)
    
    if response.code == '422'
      log_test('Input Validation - Invalid Phone', 'PASS', 'Invalid phone properly rejected')
    else
      log_test('Input Validation - Invalid Phone', 'FAIL', "Expected 422, got #{response.code}")
    end
  end
  
  def test_api_endpoints
    puts "\n🔌 Testing API Endpoints..."
    
    # Test API login
    api_login_data = {
      email: @test_user&.dig(:email) || "test@example.com",
      password: @test_user&.dig(:password) || "TestPass123!"
    }
    
    response = make_api_request('POST', '/api/v1/auth/login', api_login_data)
    
    if response.code == '200'
      log_test('API Login', 'PASS', 'API login working')
      
      # Parse response to get token
      begin
        data = JSON.parse(response.body)
        token = data.dig('data', 'token')
        
        if token
          log_test('JWT Token Generation', 'PASS', 'JWT token generated successfully')
          
          # Test protected endpoint with token
          test_protected_endpoint(token)
        else
          log_test('JWT Token Generation', 'FAIL', 'No token in response')
        end
      rescue JSON::ParserError
        log_test('JWT Token Generation', 'FAIL', 'Invalid JSON response')
      end
    else
      log_test('API Login', 'FAIL', "Expected 200, got #{response.code}")
    end
  end
  
  def test_protected_endpoint(token)
    headers = { 'Authorization' => "Bearer #{token}" }
    response = make_api_request('GET', '/api/v1/users/profile', {}, headers)
    
    if response.code == '200'
      log_test('Protected Endpoint Access', 'PASS', 'Protected endpoint accessible with token')
    else
      log_test('Protected Endpoint Access', 'FAIL', "Expected 200, got #{response.code}")
    end
  end
  
  def test_error_handling
    puts "\n⚠️ Testing Error Handling..."
    
    # Test 404
    response = make_request('GET', '/nonexistent-page')
    if response.code == '404'
      log_test('Error Handling - 404', 'PASS', '404 properly handled')
    else
      log_test('Error Handling - 404', 'FAIL', "Expected 404, got #{response.code}")
    end
    
    # Test invalid JSON
    response = make_api_request('POST', '/api/v1/auth/login', 'invalid json')
    if response.code == '400'
      log_test('Error Handling - Invalid JSON', 'PASS', 'Invalid JSON properly handled')
    else
      log_test('Error Handling - Invalid JSON', 'FAIL', "Expected 400, got #{response.code}")
    end
  end
  
  def make_request(method, path, data = nil)
    uri = URI("#{BASE_URL}#{path}")
    
    case method.upcase
    when 'GET'
      request = Net::HTTP::Get.new(uri)
    when 'POST'
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = data.to_json if data
    end
    
    # Add cookies if available
    @session_cookies.each { |key, value| request['Cookie'] = "#{key}=#{value}" }
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
    
    # Store cookies for session management
    if response['Set-Cookie']
      @session_cookies['session'] = response['Set-Cookie'].split(';').first
    end
    
    response
  end
  
  def make_api_request(method, path, data = nil, headers = {})
    uri = URI("#{BASE_URL}#{path}")
    
    case method.upcase
    when 'GET'
      request = Net::HTTP::Get.new(uri)
    when 'POST'
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = data.to_json if data
    end
    
    # Add custom headers
    headers.each { |key, value| request[key] = value }
    
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
  end
  
  def log_test(test_name, status, message)
    @test_results << { name: test_name, status: status, message: message }
    puts "  #{status == 'PASS' ? '✅' : '❌'} #{test_name}: #{message}"
  end
  
  def print_results
    puts "\n" + "=" * 60
    puts "📊 Test Results Summary"
    puts "=" * 60
    
    total_tests = @test_results.length
    passed_tests = @test_results.count { |r| r[:status] == 'PASS' }
    failed_tests = total_tests - passed_tests
    
    puts "Total Tests: #{total_tests}"
    puts "Passed: #{passed_tests} ✅"
    puts "Failed: #{failed_tests} ❌"
    puts "Success Rate: #{(passed_tests.to_f / total_tests * 100).round(1)}%"
    
    if failed_tests > 0
      puts "\n❌ Failed Tests:"
      @test_results.select { |r| r[:status] == 'FAIL' }.each do |result|
        puts "  - #{result[:name]}: #{result[:message]}"
      end
    end
    
    puts "\n🎯 Authentication System Status: #{failed_tests == 0 ? 'FULLY OPERATIONAL' : 'NEEDS ATTENTION'}"
  end
end

# Run the tests
if __FILE__ == $0
  test = AuthFunctionalityTest.new
  test.run_all_tests
end
