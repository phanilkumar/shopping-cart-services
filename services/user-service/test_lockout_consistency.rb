#!/usr/bin/env ruby

# Test script to verify account lockout consistency between email and OTP login methods
# This script tests the security fix for the lockout bypass vulnerability

require 'net/http'
require 'json'
require 'uri'

BASE_URL = 'http://localhost:3000'

def make_request(endpoint, params = {})
  uri = URI("#{BASE_URL}#{endpoint}")
  http = Net::HTTP.new(uri.host, uri.port)
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = params.to_json
  
  response = http.request(request)
  {
    status: response.code.to_i,
    body: JSON.parse(response.body) rescue response.body
  }
end

def test_email_login(email, password)
  puts "\n=== Testing Email Login ==="
  puts "Email: #{email}"
  puts "Password: #{password}"
  
  response = make_request('/api/v1/auth/login', {
    email: email,
    password: password
  })
  
  puts "Status: #{response[:status]}"
  puts "Response: #{response[:body]}"
  
  if response[:body].is_a?(Hash)
    if response[:body]['message']&.include?('locked')
      puts "✅ Account is properly locked for email login"
      return true
    elsif response[:body]['message']&.include?('Invalid email or password')
      puts "⚠️  Invalid credentials (expected if account not locked yet)"
      return false
    end
  end
  
  response[:status] == 200
end

def test_otp_login(phone, otp)
  puts "\n=== Testing OTP Login ==="
  puts "Phone: #{phone}"
  puts "OTP: #{otp}"
  
  response = make_request('/api/v1/otp/login-with-otp', {
    phone: phone,
    otp: otp
  })
  
  puts "Status: #{response[:status]}"
  puts "Response: #{response[:body]}"
  
  if response[:body].is_a?(Hash)
    if response[:body]['message']&.include?('locked')
      puts "✅ Account is properly locked for OTP login"
      return true
    elsif response[:body]['message']&.include?('Invalid')
      puts "⚠️  Invalid OTP (expected if account not locked yet)"
      return false
    end
  end
  
  response[:status] == 200
end

def main
  puts "🔒 Testing Account Lockout Consistency"
  puts "====================================="
  
  # Test credentials
  email = "phanilkumar@gmail.com"
  phone = "9876543210"
  wrong_password = "wrongpassword123"
  wrong_otp = "000000"
  
  puts "\n📋 Test Plan:"
  puts "1. Try email login with wrong password multiple times to lock account"
  puts "2. Verify OTP login is also blocked when account is locked"
  puts "3. Confirm both methods show consistent lockout behavior"
  
  # Step 1: Try to lock account via email login
  puts "\n🔐 Step 1: Attempting to lock account via email login..."
  
  locked_via_email = false
  6.times do |attempt|
    puts "\n--- Attempt #{attempt + 1} ---"
    success = test_email_login(email, wrong_password)
    
    if success
      puts "❌ Unexpected: Email login succeeded on attempt #{attempt + 1}"
      break
    end
    
    # Check if account got locked
    response = make_request('/api/v1/auth/login', {
      email: email,
      password: wrong_password
    })
    
    if response[:body].is_a?(Hash) && response[:body]['message']&.include?('locked')
      puts "🔒 Account locked via email login after #{attempt + 1} attempts"
      locked_via_email = true
      break
    end
  end
  
  if locked_via_email
    puts "\n🔐 Step 2: Testing OTP login with locked account..."
    
    # Step 2: Try OTP login with locked account
    otp_response = test_otp_login(phone, wrong_otp)
    
    if otp_response
      puts "❌ SECURITY VULNERABILITY: OTP login succeeded despite account being locked!"
      puts "   This means the lockout bypass vulnerability still exists."
    else
      puts "✅ SECURITY FIXED: OTP login properly blocked when account is locked"
      puts "   The lockout mechanism now works consistently across both login methods."
    end
  else
    puts "\n⚠️  Could not lock account via email login. This might be because:"
    puts "   - Account is already locked"
    puts "   - Server is not running"
    puts "   - Different lockout threshold"
  end
  
  puts "\n📊 Test Summary:"
  puts "================="
  if locked_via_email
    puts "✅ Account lockout via email: WORKING"
    puts "✅ Account lockout via OTP: #{otp_response ? 'FAILED (VULNERABILITY)' : 'WORKING (FIXED)'}"
  else
    puts "⚠️  Could not complete full test - account lockout via email not achieved"
  end
  
  puts "\n🔧 To manually test:"
  puts "1. Start the Rails server: rails server"
  puts "2. Run this script: ruby test_lockout_consistency.rb"
  puts "3. Or test manually via API calls"
end

if __FILE__ == $0
  main
end
