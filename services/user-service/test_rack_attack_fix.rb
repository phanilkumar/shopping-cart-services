#!/usr/bin/env ruby

# Test script to verify Rack::Attack NoMethodError fix
# This script tests that Rack::Attack doesn't crash with nil requests

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

def test_multiple_login_attempts
  puts "🔒 Testing Rack::Attack NoMethodError Fix"
  puts "========================================"
  
  email = "test@example.com"
  wrong_password = "wrongpassword123"
  
  puts "\n📋 Test Plan:"
  puts "1. Make multiple login attempts to trigger Rack::Attack"
  puts "2. Verify no NoMethodError occurs"
  puts "3. Check that rate limiting works properly"
  
  puts "\n🔐 Making multiple login attempts..."
  
  success_count = 0
  error_count = 0
  rate_limited_count = 0
  
  20.times do |attempt|
    puts "\n--- Attempt #{attempt + 1} ---"
    
    begin
      response = make_request('/users/sign_in', {
        user: {
          email: email,
          password: wrong_password
        }
      })
      
      puts "Status: #{response[:status]}"
      
      if response[:status] == 200
        success_count += 1
        puts "✅ Login succeeded (unexpected)"
      elsif response[:status] == 401
        puts "⚠️  Invalid credentials (expected)"
      elsif response[:status] == 429
        rate_limited_count += 1
        puts "🚫 Rate limited (expected after multiple attempts)"
      elsif response[:status] == 403
        puts "🚫 Access forbidden (Rack::Attack blocklist)"
      else
        puts "❓ Unexpected status: #{response[:status]}"
      end
      
      # Check for error messages
      if response[:body].is_a?(Hash)
        if response[:body]['message']&.include?('NoMethodError')
          puts "❌ CRITICAL: NoMethodError still occurring!"
          error_count += 1
        elsif response[:body]['message']&.include?('Access denied')
          puts "✅ Rack::Attack working properly (access denied)"
        end
      end
      
    rescue => e
      puts "❌ Request failed: #{e.message}"
      error_count += 1
    end
    
    # Small delay between requests
    sleep(0.1)
  end
  
  puts "\n📊 Test Results:"
  puts "================"
  puts "Total attempts: 20"
  puts "Successful logins: #{success_count}"
  puts "Rate limited responses: #{rate_limited_count}"
  puts "Errors encountered: #{error_count}"
  
  if error_count == 0
    puts "\n✅ SUCCESS: No NoMethodError occurred!"
    puts "   Rack::Attack is working properly with the fix."
  else
    puts "\n❌ FAILURE: #{error_count} errors occurred!"
    puts "   The NoMethodError fix may not be working properly."
  end
  
  if rate_limited_count > 0
    puts "\n✅ Rate limiting is working: #{rate_limited_count} requests were rate limited"
  else
    puts "\n⚠️  No rate limiting observed - this might be normal depending on configuration"
  end
  
  puts "\n🔧 Manual Testing Instructions:"
  puts "1. Start Rails server: rails server"
  puts "2. Try logging in multiple times at: http://localhost:3000/users/sign_in"
  puts "3. Check server logs for any NoMethodError messages"
  puts "4. Verify that rate limiting kicks in after multiple attempts"
end

def test_api_login_attempts
  puts "\n🔒 Testing API Login Rate Limiting"
  puts "=================================="
  
  email = "test@example.com"
  wrong_password = "wrongpassword123"
  
  puts "\n🔐 Making multiple API login attempts..."
  
  success_count = 0
  error_count = 0
  rate_limited_count = 0
  
  10.times do |attempt|
    puts "\n--- API Attempt #{attempt + 1} ---"
    
    begin
      response = make_request('/api/v1/auth/login', {
        email: email,
        password: wrong_password
      })
      
      puts "Status: #{response[:status]}"
      
      if response[:status] == 200
        success_count += 1
        puts "✅ API login succeeded (unexpected)"
      elsif response[:status] == 401
        puts "⚠️  Invalid credentials (expected)"
      elsif response[:status] == 429
        rate_limited_count += 1
        puts "🚫 API rate limited (expected)"
      else
        puts "❓ Unexpected API status: #{response[:status]}"
      end
      
    rescue => e
      puts "❌ API request failed: #{e.message}"
      error_count += 1
    end
    
    sleep(0.1)
  end
  
  puts "\n📊 API Test Results:"
  puts "===================="
  puts "API attempts: 10"
  puts "API errors: #{error_count}"
  puts "API rate limited: #{rate_limited_count}"
end

def main
  begin
    test_multiple_login_attempts
    test_api_login_attempts
    
    puts "\n🎯 Summary:"
    puts "==========="
    puts "If no NoMethodError occurred during the tests, the fix is working!"
    puts "Rack::Attack should now handle nil requests gracefully."
    
  rescue => e
    puts "\n❌ Test script failed: #{e.message}"
    puts "Make sure the Rails server is running on #{BASE_URL}"
  end
end

if __FILE__ == $0
  main
end
