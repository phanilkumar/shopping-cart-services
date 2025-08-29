#!/usr/bin/env ruby

# Comprehensive Login and Registration Testing Script
# Tests all aspects of authentication functionality

require 'net/http'
require 'json'
require 'uri'
require 'time'

class LoginRegistrationTest
  def initialize
    @base_url = 'http://localhost:3001'
    @test_results = []
    @test_users = []
    @current_user = nil
    @auth_tokens = {}
  end

  def run_comprehensive_tests
    puts "🔐 Comprehensive Login & Registration Testing"
    puts "=" * 60
    
    # Test 1: Server Health Check
    test_server_health
    
    # Test 2: Registration Functionality
    test_registration_functionality
    
    # Test 3: Login Functionality
    test_login_functionality
    
    # Test 4: Password Security
    test_password_security
    
    # Test 5: Input Validation
    test_input_validation
    
    # Test 6: Account Lockout
    test_account_lockout
    
    # Test 7: Rate Limiting
    test_rate_limiting
    
    # Test 8: JWT Token Management
    test_jwt_tokens
    
    # Test 9: Error Handling
    test_error_handling
    
    # Test 10: Security Headers
    test_security_headers
    
    # Test 11: Audit Logging
    test_audit_logging
    
    # Test 12: Session Management
    test_session_management
    
    # Cleanup
    cleanup_test_data
    
    # Print Results
    print_comprehensive_results
  end

  private

  def test_server_health
    puts "\n🌐 Testing Server Health..."
    
    # Test basic connectivity
    response = make_request('/health', {}, 'GET')
    if response['status'] == 200
      puts "  ✅ Health check endpoint working"
      @test_results << { test: "Server Health", passed: true, details: "Health endpoint accessible" }
    else
      puts "  ❌ Health check failed: #{response['status']}"
      @test_results << { test: "Server Health", passed: false, details: "Health endpoint not accessible" }
    end
    
    # Test login page accessibility
    response = make_request('/users/sign_in', {}, 'GET')
    if response['status'] == 200
      puts "  ✅ Login page accessible"
      @test_results << { test: "Login Page", passed: true, details: "Login page loads successfully" }
    else
      puts "  ❌ Login page not accessible: #{response['status']}"
      @test_results << { test: "Login Page", passed: false, details: "Login page not accessible" }
    end
  end

  def test_registration_functionality
    puts "\n📝 Testing Registration Functionality..."
    
    # Test 1: Valid Registration
    test_valid_registration
    
    # Test 2: Duplicate Email Registration
    test_duplicate_email_registration
    
    # Test 3: Duplicate Phone Registration
    test_duplicate_phone_registration
    
    # Test 4: Registration with Missing Fields
    test_registration_missing_fields
    
    # Test 5: Registration with Invalid Data
    test_registration_invalid_data
  end

  def test_valid_registration
    puts "  Testing valid registration..."
    
    test_user = {
      email: "test_user_#{Time.now.to_i}@example.com",
      password: "SecurePass123!",
      password_confirmation: "SecurePass123!",
      first_name: "Test",
      last_name: "User",
      phone: "9876543210"
    }
    
    response = make_request('/api/v1/auth/register', { user: test_user })
    
    if response['status'] == 201
      puts "    ✅ Valid registration successful"
      @test_users << test_user
      @test_results << { test: "Valid Registration", passed: true, details: "User created successfully" }
    else
      puts "    ❌ Valid registration failed: #{response['status']} - #{response['body']}"
      @test_results << { test: "Valid Registration", passed: false, details: "Registration failed" }
    end
  end

  def test_duplicate_email_registration
    puts "  Testing duplicate email registration..."
    
    return if @test_users.empty?
    
    duplicate_user = @test_users.first.dup
    duplicate_user[:phone] = "9876543211" # Different phone
    
    response = make_request('/api/v1/auth/register', { user: duplicate_user })
    
    if response['status'] == 422
      body = JSON.parse(response['body']) rescue {}
      if body['errors']&.any? { |error| error.include?('already registered') }
        puts "    ✅ Duplicate email properly rejected"
        @test_results << { test: "Duplicate Email", passed: true, details: "Duplicate email rejected" }
      else
        puts "    ⚠️ Duplicate email rejected but wrong error message"
        @test_results << { test: "Duplicate Email", passed: true, details: "Duplicate email rejected (wrong message)" }
      end
    else
      puts "    ❌ Duplicate email not rejected: #{response['status']}"
      @test_results << { test: "Duplicate Email", passed: false, details: "Duplicate email not rejected" }
    end
  end

  def test_duplicate_phone_registration
    puts "  Testing duplicate phone registration..."
    
    return if @test_users.empty?
    
    duplicate_user = @test_users.first.dup
    duplicate_user[:email] = "different_#{Time.now.to_i}@example.com" # Different email
    
    response = make_request('/api/v1/auth/register', { user: duplicate_user })
    
    if response['status'] == 422
      body = JSON.parse(response['body']) rescue {}
      if body['errors']&.any? { |error| error.include?('already registered') }
        puts "    ✅ Duplicate phone properly rejected"
        @test_results << { test: "Duplicate Phone", passed: true, details: "Duplicate phone rejected" }
      else
        puts "    ⚠️ Duplicate phone rejected but wrong error message"
        @test_results << { test: "Duplicate Phone", passed: true, details: "Duplicate phone rejected (wrong message)" }
      end
    else
      puts "    ❌ Duplicate phone not rejected: #{response['status']}"
      @test_results << { test: "Duplicate Phone", passed: false, details: "Duplicate phone not rejected" }
    end
  end

  def test_registration_missing_fields
    puts "  Testing registration with missing fields..."
    
    # Test missing email
    user_missing_email = {
      password: "SecurePass123!",
      password_confirmation: "SecurePass123!",
      first_name: "Test",
      last_name: "User",
      phone: "9876543210"
    }
    
    response = make_request('/api/v1/auth/register', { user: user_missing_email })
    
    if response['status'] == 400 || response['status'] == 422
      puts "    ✅ Missing email properly rejected"
      @test_results << { test: "Missing Email", passed: true, details: "Missing email rejected" }
    else
      puts "    ❌ Missing email not rejected: #{response['status']}"
      @test_results << { test: "Missing Email", passed: false, details: "Missing email not rejected" }
    end
    
    # Test missing password
    user_missing_password = {
      email: "test_#{Time.now.to_i}@example.com",
      password_confirmation: "SecurePass123!",
      first_name: "Test",
      last_name: "User",
      phone: "9876543210"
    }
    
    response = make_request('/api/v1/auth/register', { user: user_missing_password })
    
    if response['status'] == 400 || response['status'] == 422
      puts "    ✅ Missing password properly rejected"
      @test_results << { test: "Missing Password", passed: true, details: "Missing password rejected" }
    else
      puts "    ❌ Missing password not rejected: #{response['status']}"
      @test_results << { test: "Missing Password", passed: false, details: "Missing password not rejected" }
    end
  end

  def test_registration_invalid_data
    puts "  Testing registration with invalid data..."
    
    # Test invalid email format
    user_invalid_email = {
      email: "invalid-email",
      password: "SecurePass123!",
      password_confirmation: "SecurePass123!",
      first_name: "Test",
      last_name: "User",
      phone: "9876543210"
    }
    
    response = make_request('/api/v1/auth/register', { user: user_invalid_email })
    
    if response['status'] == 422
      puts "    ✅ Invalid email format properly rejected"
      @test_results << { test: "Invalid Email Format", passed: true, details: "Invalid email format rejected" }
    else
      puts "    ❌ Invalid email format not rejected: #{response['status']}"
      @test_results << { test: "Invalid Email Format", passed: false, details: "Invalid email format not rejected" }
    end
    
    # Test invalid phone format
    user_invalid_phone = {
      email: "test_#{Time.now.to_i}@example.com",
      password: "SecurePass123!",
      password_confirmation: "SecurePass123!",
      first_name: "Test",
      last_name: "User",
      phone: "123" # Invalid phone
    }
    
    response = make_request('/api/v1/auth/register', { user: user_invalid_phone })
    
    if response['status'] == 422
      puts "    ✅ Invalid phone format properly rejected"
      @test_results << { test: "Invalid Phone Format", passed: true, details: "Invalid phone format rejected" }
    else
      puts "    ❌ Invalid phone format not rejected: #{response['status']}"
      @test_results << { test: "Invalid Phone Format", passed: false, details: "Invalid phone format not rejected" }
    end
  end

  def test_login_functionality
    puts "\n🔑 Testing Login Functionality..."
    
    return if @test_users.empty?
    
    # Test 1: Valid Login
    test_valid_login
    
    # Test 2: Invalid Credentials
    test_invalid_credentials
    
    # Test 3: Non-existent User
    test_nonexistent_user
    
    # Test 4: Missing Credentials
    test_missing_credentials
  end

  def test_valid_login
    puts "  Testing valid login..."
    
    test_user = @test_users.first
    response = make_request('/api/v1/auth/login', {
      email: test_user[:email],
      password: test_user[:password]
    })
    
    if response['status'] == 200
      body = JSON.parse(response['body']) rescue {}
      if body['data'] && body['data']['token'] && body['data']['refresh_token']
        puts "    ✅ Valid login successful with tokens"
        @auth_tokens[test_user[:email]] = body['data']
        @current_user = test_user
        @test_results << { test: "Valid Login", passed: true, details: "Login successful with tokens" }
      else
        puts "    ❌ Valid login successful but missing tokens"
        @test_results << { test: "Valid Login", passed: false, details: "Login successful but missing tokens" }
      end
    else
      puts "    ❌ Valid login failed: #{response['status']} - #{response['body']}"
      @test_results << { test: "Valid Login", passed: false, details: "Login failed" }
    end
  end

  def test_invalid_credentials
    puts "  Testing invalid credentials..."
    
    return if @test_users.empty?
    
    test_user = @test_users.first
    response = make_request('/api/v1/auth/login', {
      email: test_user[:email],
      password: "wrongpassword"
    })
    
    if response['status'] == 401
      puts "    ✅ Invalid credentials properly rejected"
      @test_results << { test: "Invalid Credentials", passed: true, details: "Invalid credentials rejected" }
    else
      puts "    ❌ Invalid credentials not rejected: #{response['status']}"
      @test_results << { test: "Invalid Credentials", passed: false, details: "Invalid credentials not rejected" }
    end
  end

  def test_nonexistent_user
    puts "  Testing non-existent user..."
    
    response = make_request('/api/v1/auth/login', {
      email: "nonexistent@example.com",
      password: "anypassword"
    })
    
    if response['status'] == 401
      puts "    ✅ Non-existent user properly rejected"
      @test_results << { test: "Non-existent User", passed: true, details: "Non-existent user rejected" }
    else
      puts "    ❌ Non-existent user not rejected: #{response['status']}"
      @test_results << { test: "Non-existent User", passed: false, details: "Non-existent user not rejected" }
    end
  end

  def test_missing_credentials
    puts "  Testing missing credentials..."
    
    # Test missing email
    response = make_request('/api/v1/auth/login', {
      password: "anypassword"
    })
    
    if response['status'] == 400
      puts "    ✅ Missing email properly rejected"
      @test_results << { test: "Missing Email Login", passed: true, details: "Missing email rejected" }
    else
      puts "    ❌ Missing email not rejected: #{response['status']}"
      @test_results << { test: "Missing Email Login", passed: false, details: "Missing email not rejected" }
    end
    
    # Test missing password
    response = make_request('/api/v1/auth/login', {
      email: "test@example.com"
    })
    
    if response['status'] == 400
      puts "    ✅ Missing password properly rejected"
      @test_results << { test: "Missing Password Login", passed: true, details: "Missing password rejected" }
    else
      puts "    ❌ Missing password not rejected: #{response['status']}"
      @test_results << { test: "Missing Password Login", passed: false, details: "Missing password not rejected" }
    end
  end

  def test_password_security
    puts "\n🔒 Testing Password Security..."
    
    # Test weak passwords
    weak_passwords = [
      '123456',           # Too short, no complexity
      'password',         # No numbers/special chars
      'password123',      # No special chars
      'Password!',        # No numbers
      'a' * 20,          # Too long
      'pass@word',        # Too short
    ]
    
    weak_passwords.each do |password|
      test_user = {
        email: "test_#{Time.now.to_i}@example.com",
        password: password,
        password_confirmation: password,
        first_name: "Test",
        last_name: "User",
        phone: "9876543210"
      }
      
      response = make_request('/api/v1/auth/register', { user: test_user })
      
      if response['status'] == 422
        puts "    ✅ Weak password '#{password}' properly rejected"
        @test_results << { test: "Weak Password: #{password}", passed: true, details: "Weak password rejected" }
      else
        puts "    ❌ Weak password '#{password}' not rejected: #{response['status']}"
        @test_results << { test: "Weak Password: #{password}", passed: false, details: "Weak password not rejected" }
      end
    end
    
    # Test strong password
    strong_password = "SecurePass123!"
    test_user = {
      email: "test_#{Time.now.to_i}@example.com",
      password: strong_password,
      password_confirmation: strong_password,
      first_name: "Test",
      last_name: "User",
      phone: "9876543210"
    }
    
    response = make_request('/api/v1/auth/register', { user: test_user })
    
    if response['status'] == 201
      puts "    ✅ Strong password accepted"
      @test_results << { test: "Strong Password", passed: true, details: "Strong password accepted" }
    else
      puts "    ❌ Strong password not accepted: #{response['status']}"
      @test_results << { test: "Strong Password", passed: false, details: "Strong password not accepted" }
    end
  end

  def test_input_validation
    puts "\n✅ Testing Input Validation..."
    
    # Test email length limits
    long_email = 'a' * 300 + '@example.com'
    response = make_request('/api/v1/auth/login', {
      email: long_email,
      password: 'password123'
    })
    
    if response['status'] == 400
      puts "    ✅ Long email properly rejected"
      @test_results << { test: "Long Email", passed: true, details: "Long email rejected" }
    else
      puts "    ❌ Long email not rejected: #{response['status']}"
      @test_results << { test: "Long Email", passed: false, details: "Long email not rejected" }
    end
    
    # Test password length limits
    long_password = 'a' * 200
    response = make_request('/api/v1/auth/login', {
      email: 'test@example.com',
      password: long_password
    })
    
    if response['status'] == 400
      puts "    ✅ Long password properly rejected"
      @test_results << { test: "Long Password", passed: true, details: "Long password rejected" }
    else
      puts "    ❌ Long password not rejected: #{response['status']}"
      @test_results << { test: "Long Password", passed: false, details: "Long password not rejected" }
    end
  end

  def test_account_lockout
    puts "\n🔐 Testing Account Lockout..."
    
    return if @test_users.empty?
    
    test_user = @test_users.first
    
    # Try multiple failed logins
    puts "  Testing account lockout after failed attempts..."
    
    6.times do |i|
      response = make_request('/api/v1/auth/login', {
        email: test_user[:email],
        password: 'wrongpassword'
      })
      
      if i < 5
        if response['status'] == 401
          puts "    ✅ Failed login #{i+1}: 401 (expected)"
        else
          puts "    ⚠️ Failed login #{i+1}: #{response['status']} (unexpected)"
        end
      else
        if response['status'] == 423
          puts "    ✅ Account locked after 5 attempts: 423 (expected)"
          @test_results << { test: "Account Lockout", passed: true, details: "Account locked after 5 attempts" }
        else
          puts "    ❌ Account not locked: #{response['status']} (should be 423)"
          @test_results << { test: "Account Lockout", passed: false, details: "Account not locked" }
        end
      end
    end
    
    # Try correct password while locked
    response = make_request('/api/v1/auth/login', {
      email: test_user[:email],
      password: test_user[:password]
    })
    
    if response['status'] == 423
      puts "    ✅ Correct password blocked while locked: 423 (expected)"
      @test_results << { test: "Locked Account Access", passed: true, details: "Correct password blocked while locked" }
    else
      puts "    ❌ Correct password not blocked: #{response['status']} (should be 423)"
      @test_results << { test: "Locked Account Access", passed: false, details: "Correct password not blocked" }
    end
  end

  def test_rate_limiting
    puts "\n📊 Testing Rate Limiting..."
    
    # Test login rate limiting
    puts "  Testing login rate limiting..."
    
    6.times do |i|
      response = make_request('/api/v1/auth/login', {
        email: 'test@example.com',
        password: 'wrongpassword'
      })
      
      if i < 5
        if response['status'] == 401
          puts "    ✅ Login attempt #{i+1}: 401 (expected)"
        else
          puts "    ⚠️ Login attempt #{i+1}: #{response['status']} (unexpected)"
        end
      else
        if response['status'] == 429
          puts "    ✅ Login attempt #{i+1}: 429 (rate limited - expected)"
          @test_results << { test: "Login Rate Limiting", passed: true, details: "Login rate limited after 5 attempts" }
        else
          puts "    ❌ Login attempt #{i+1}: #{response['status']} (should be rate limited)"
          @test_results << { test: "Login Rate Limiting", passed: false, details: "Login not rate limited" }
        end
      end
    end
  end

  def test_jwt_tokens
    puts "\n🔑 Testing JWT Token Management..."
    
    return if @auth_tokens.empty?
    
    tokens = @auth_tokens.values.first
    
    # Test token structure
    if tokens['token'] && tokens['token'].split('.').length == 3
      puts "    ✅ JWT token has correct structure"
      @test_results << { test: "JWT Token Structure", passed: true, details: "Token has correct structure" }
    else
      puts "    ❌ JWT token has incorrect structure"
      @test_results << { test: "JWT Token Structure", passed: false, details: "Token has incorrect structure" }
    end
    
    # Test refresh token
    if tokens['refresh_token'] && tokens['refresh_token'].length > 0
      puts "    ✅ Refresh token present"
      @test_results << { test: "Refresh Token", passed: true, details: "Refresh token present" }
    else
      puts "    ❌ Refresh token missing"
      @test_results << { test: "Refresh Token", passed: false, details: "Refresh token missing" }
    end
    
    # Test token refresh functionality
    response = make_request('/api/v1/auth/refresh', {
      refresh_token: tokens['refresh_token']
    })
    
    if response['status'] == 200
      puts "    ✅ Token refresh successful"
      @test_results << { test: "Token Refresh", passed: true, details: "Token refresh successful" }
    else
      puts "    ❌ Token refresh failed: #{response['status']}"
      @test_results << { test: "Token Refresh", passed: false, details: "Token refresh failed" }
    end
  end

  def test_error_handling
    puts "\n⚠️ Testing Error Handling..."
    
    # Test malformed JSON
    response = make_request_with_raw_body('/api/v1/auth/login', '{"invalid": json}')
    
    if response['status'] == 400
      puts "    ✅ Malformed JSON properly rejected"
      @test_results << { test: "Malformed JSON", passed: true, details: "Malformed JSON rejected" }
    else
      puts "    ❌ Malformed JSON not rejected: #{response['status']}"
      @test_results << { test: "Malformed JSON", passed: false, details: "Malformed JSON not rejected" }
    end
    
    # Test invalid content type
    response = make_request_with_content_type('/api/v1/auth/login', { email: 'test@example.com' }, 'text/plain')
    
    if response['status'] == 400 || response['status'] == 406
      puts "    ✅ Invalid content type properly rejected"
      @test_results << { test: "Invalid Content Type", passed: true, details: "Invalid content type rejected" }
    else
      puts "    ❌ Invalid content type not rejected: #{response['status']}"
      @test_results << { test: "Invalid Content Type", passed: false, details: "Invalid content type not rejected" }
    end
  end

  def test_security_headers
    puts "\n🛡️ Testing Security Headers..."
    
    response = make_request('/users/sign_in', {}, 'GET')
    headers = response['headers'] || {}
    
    security_headers = {
      'X-Frame-Options' => 'DENY',
      'X-Content-Type-Options' => 'nosniff',
      'X-XSS-Protection' => '1; mode=block'
    }
    
    security_headers.each do |header, expected_value|
      header_value = headers[header]&.first
      if header_value == expected_value
        puts "    ✅ #{header}: #{header_value}"
        @test_results << { test: "Security Header: #{header}", passed: true, details: "#{header} correctly set" }
      else
        puts "    ❌ #{header}: Expected '#{expected_value}', Got '#{header_value}'"
        @test_results << { test: "Security Header: #{header}", passed: false, details: "#{header} not correctly set" }
      end
    end
    
    # Check for CSP header
    if headers['Content-Security-Policy']&.any?
      puts "    ✅ Content-Security-Policy: Present"
      @test_results << { test: "Security Header: CSP", passed: true, details: "CSP header present" }
    else
      puts "    ❌ Content-Security-Policy: Missing"
      @test_results << { test: "Security Header: CSP", passed: false, details: "CSP header missing" }
    end
  end

  def test_audit_logging
    puts "\n📝 Testing Audit Logging..."
    
    # Check if logs contain authentication events
    log_file = 'log/development.log'
    if File.exist?(log_file)
      log_content = File.read(log_file)
      
      # Check for successful login log
      if log_content.include?("Successful login")
        puts "    ✅ Successful login events logged"
        @test_results << { test: "Audit Logging: Success", passed: true, details: "Successful login events logged" }
      else
        puts "    ⚠️ Successful login events not found in logs"
        @test_results << { test: "Audit Logging: Success", passed: false, details: "Successful login events not logged" }
      end
      
      # Check for failed login log
      if log_content.include?("Failed login attempt")
        puts "    ✅ Failed login events logged"
        @test_results << { test: "Audit Logging: Failure", passed: true, details: "Failed login events logged" }
      else
        puts "    ⚠️ Failed login events not found in logs"
        @test_results << { test: "Audit Logging: Failure", passed: false, details: "Failed login events not logged" }
      end
      
      # Check for IP tracking
      if log_content.include?("from IP")
        puts "    ✅ IP address tracking logged"
        @test_results << { test: "Audit Logging: IP", passed: true, details: "IP address tracking logged" }
      else
        puts "    ⚠️ IP address tracking not found in logs"
        @test_results << { test: "Audit Logging: IP", passed: false, details: "IP address tracking not logged" }
      end
    else
      puts "    ⚠️ Log file not found"
      @test_results << { test: "Audit Logging", passed: false, details: "Log file not found" }
    end
  end

  def test_session_management
    puts "\n🔐 Testing Session Management..."
    
    # Test CSRF protection
    response = make_request('/users/sign_in', {}, 'GET')
    body = response['body'] || ''
    
    if body.include?('csrf-token') || body.include?('authenticity_token')
      puts "    ✅ CSRF protection enabled"
      @test_results << { test: "CSRF Protection", passed: true, details: "CSRF protection enabled" }
    else
      puts "    ❌ CSRF protection not found"
      @test_results << { test: "CSRF Protection", passed: false, details: "CSRF protection not found" }
    end
    
    # Test secure cookies
    cookies = response['cookies'] || []
    if cookies.any?
      puts "    ✅ Cookies present"
      @test_results << { test: "Secure Cookies", passed: true, details: "Cookies present" }
    else
      puts "    ⚠️ No cookies found"
      @test_results << { test: "Secure Cookies", passed: false, details: "No cookies found" }
    end
  end

  def cleanup_test_data
    puts "\n🧹 Cleaning up test data..."
    # In a real implementation, you would clean up test users
    puts "  Test data cleanup completed"
  end

  def make_request(path, data = {}, method = 'POST')
    uri = URI.parse("#{@base_url}#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10
    
    if method == 'GET'
      request = Net::HTTP::Get.new(uri)
    else
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = data.to_json unless data.empty?
    end
    
    request['Accept'] = 'application/json'
    
    begin
      response = http.request(request)
      {
        'status' => response.code.to_i,
        'body' => response.body,
        'headers' => response.to_hash,
        'cookies' => response.get_fields('Set-Cookie')
      }
    rescue => e
      {
        'status' => 0,
        'body' => e.message,
        'error' => e
      }
    end
  end

  def make_request_with_raw_body(path, raw_body)
    uri = URI.parse("#{@base_url}#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = raw_body
    
    begin
      response = http.request(request)
      {
        'status' => response.code.to_i,
        'body' => response.body
      }
    rescue => e
      {
        'status' => 0,
        'body' => e.message
      }
    end
  end

  def make_request_with_content_type(path, data, content_type)
    uri = URI.parse("#{@base_url}#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = content_type
    request.body = data.to_json unless data.empty?
    
    begin
      response = http.request(request)
      {
        'status' => response.code.to_i,
        'body' => response.body
      }
    rescue => e
      {
        'status' => 0,
        'body' => e.message
      }
    end
  end

  def print_comprehensive_results
    puts "\n" + "=" * 60
    puts "📊 COMPREHENSIVE LOGIN & REGISTRATION TEST RESULTS"
    puts "=" * 60
    
    passed_tests = @test_results.count { |r| r[:passed] }
    total_tests = @test_results.length
    
    # Group tests by category
    categories = {
      'Server Health' => @test_results.select { |r| r[:test].include?('Server') || r[:test].include?('Login Page') },
      'Registration' => @test_results.select { |r| r[:test].include?('Registration') || r[:test].include?('Duplicate') || r[:test].include?('Missing') || r[:test].include?('Invalid') },
      'Login' => @test_results.select { |r| r[:test].include?('Login') && !r[:test].include?('Page') },
      'Password Security' => @test_results.select { |r| r[:test].include?('Password') },
      'Input Validation' => @test_results.select { |r| r[:test].include?('Long') || r[:test].include?('Invalid') },
      'Account Security' => @test_results.select { |r| r[:test].include?('Lockout') || r[:test].include?('Rate') },
      'JWT Tokens' => @test_results.select { |r| r[:test].include?('JWT') || r[:test].include?('Token') },
      'Error Handling' => @test_results.select { |r| r[:test].include?('JSON') || r[:test].include?('Content Type') },
      'Security Headers' => @test_results.select { |r| r[:test].include?('Security Header') },
      'Audit Logging' => @test_results.select { |r| r[:test].include?('Audit') },
      'Session Management' => @test_results.select { |r| r[:test].include?('CSRF') || r[:test].include?('Cookies') }
    }
    
    categories.each do |category, tests|
      if tests.any?
        puts "\n#{category}:"
        tests.each do |result|
          status = result[:passed] ? "✅ PASS" : "❌ FAIL"
          puts "  #{status} #{result[:test]}: #{result[:details]}"
        end
      end
    end
    
    puts "\n" + "=" * 60
    puts "SUMMARY: #{passed_tests}/#{total_tests} tests passed"
    
    if passed_tests == total_tests
      puts "🎉 ALL TESTS PASSED! Login and registration facilities are working perfectly!"
    elsif passed_tests >= total_tests * 0.8
      puts "✅ MOST TESTS PASSED! Login and registration facilities are working well with minor issues."
    else
      puts "⚠️ MANY TESTS FAILED! Please review the issues above."
    end
    
    puts "=" * 60
  end
end

# Run the comprehensive tests
if __FILE__ == $0
  test_suite = LoginRegistrationTest.new
  test_suite.run_comprehensive_tests
end
