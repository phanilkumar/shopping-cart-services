#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test script to verify login rate limiting
require 'net/http'
require 'json'
require 'uri'

def test_login_rate_limiting
  base_url = 'http://localhost:3000'
  email = 'phanilkumar@gmail.com'
  password = 'wrongpassword'
  
  puts "🔐 Testing Login Rate Limiting"
  puts "=" * 50
  puts "Email: #{email}"
  puts "Password: #{password} (intentionally wrong)"
  puts "Expected: 5 attempts allowed, then 429 rate limited"
  puts ""
  
  success_count = 0
  rate_limited = false
  
  (1..7).each do |i|
    puts "Attempt #{i}:"
    
    begin
      uri = URI("#{base_url}/users/sign_in")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 10
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = {
        user: { email: email, password: password }
      }.to_json
      
      response = http.request(request)
      status = response.code.to_i
      
      if status == 401
        success_count += 1
        puts "  ✅ 401 (Unauthorized - expected for wrong password)"
      elsif status == 429
        rate_limited = true
        puts "  🚫 429 (Rate Limited!)"
        
        # Parse response body for rate limit info
        begin
          body = JSON.parse(response.body)
          puts "  Error: #{body['error']}" if body['error']
          puts "  Retry After: #{body['retry_after']} seconds" if body['retry_after']
        rescue
          puts "  Response: #{response.body[0..100]}..."
        end
        
        break
      else
        puts "  ❌ #{status} (Unexpected status)"
      end
      
    rescue => e
      puts "  ❌ Error: #{e.message}"
    end
    
    sleep(0.5) # Small delay between requests
  end
  
  puts ""
  puts "📊 Results:"
  puts "  Successful attempts: #{success_count}"
  puts "  Rate limited: #{rate_limited ? 'Yes' : 'No'}"
  
  if rate_limited && success_count == 5
    puts "  ✅ Rate limiting is working correctly!"
  elsif rate_limited
    puts "  ⚠️  Rate limiting triggered but after #{success_count} attempts (expected 5)"
  else
    puts "  ❌ Rate limiting is NOT working!"
  end
  
  puts ""
  puts "💡 Tips:"
  puts "  • Check if Rack::Attack is properly configured"
  puts "  • Verify the login route matches the rate limit rule"
  puts "  • Check Rails logs for rate limiting events"
  puts "  • Use the frontend test page at /security/rate-limit-test"
end

# Run the test
test_login_rate_limiting
