#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for automatic account unlock after 10 minutes
require 'net/http'
require 'json'
require 'uri'

def test_auto_unlock
  base_url = 'http://localhost:3000'
  email = 'phanilkumar@gmail.com'
  password = 'wrongpassword'
  
  puts "🔒 Testing Automatic Account Unlock (10 minutes)"
  puts "=" * 60
  puts "Email: #{email}"
  puts "Password: #{password} (intentionally wrong)"
  puts "Expected: 5 attempts → Account locked → Auto-unlock after 10 minutes"
  puts ""
  
  # Step 1: Lock the account with 5 failed attempts
  puts "Step 1: Locking account with 5 failed attempts..."
  lock_account(base_url, email, password)
  
  # Step 2: Test that account is locked
  puts "\nStep 2: Verifying account is locked..."
  test_locked_account(base_url, email, password)
  
  # Step 3: Simulate time passage (in real scenario, wait 10 minutes)
  puts "\nStep 3: Simulating 10 minutes passage..."
  puts "In a real scenario, you would wait 10 minutes here."
  puts "For testing, we'll modify the locked_at timestamp in the database."
  
  # Note: In a real test, you would wait 10 minutes or modify the database
  puts "\nTo test auto-unlock:"
  puts "1. Wait 10 minutes, OR"
  puts "2. Run: rails console"
  puts "   user = User.find_by(email: '#{email}')"
  puts "   user.update!(locked_at: 11.minutes.ago)"
  puts "   exit"
  puts "3. Then try logging in again"
end

def lock_account(base_url, email, password)
  success_count = 0
  
  (1..6).each do |i|
    puts "  Attempt #{i}:"
    
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
        puts "    ✅ 401 (Unauthorized - expected)"
      elsif status == 423
        puts "    🔒 423 (Account Locked!)"
        
        # Parse response for auto-unlock info
        begin
          body = JSON.parse(response.body)
          puts "    Message: #{body['message']}" if body['message']
          puts "    Remaining seconds: #{body['remaining_seconds']}" if body['remaining_seconds']
          puts "    Auto-unlock: #{body['auto_unlock']}" if body['auto_unlock']
        rescue
          puts "    Response: #{response.body[0..100]}..."
        end
        
        break
      else
        puts "    ❌ #{status} (Unexpected status)"
      end
      
    rescue => e
      puts "    ❌ Error: #{e.message}"
    end
    
    sleep(0.5)
  end
  
  puts "  Successfully made #{success_count} attempts before account lockout"
end

def test_locked_account(base_url, email, password)
  puts "  Testing locked account..."
  
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
    
    if status == 423
      puts "    ✅ 423 (Account Locked - as expected)"
      
      begin
        body = JSON.parse(response.body)
        puts "    Message: #{body['message']}" if body['message']
        puts "    Remaining seconds: #{body['remaining_seconds']}" if body['remaining_seconds']
        puts "    Expires at: #{body['expires_at']}" if body['expires_at']
        puts "    Auto-unlock enabled: #{body['auto_unlock']}" if body['auto_unlock']
      rescue
        puts "    Response: #{response.body[0..100]}..."
      end
    else
      puts "    ❌ #{status} (Expected 423 - Account Locked)"
    end
    
  rescue => e
    puts "    ❌ Error: #{e.message}"
  end
end

def show_manual_test_instructions
  puts "\n" + "=" * 60
  puts "📋 MANUAL TESTING INSTRUCTIONS"
  puts "=" * 60
  
  puts "\n1. **Lock the account** (run this script)"
  puts "2. **Wait 10 minutes** OR modify database:"
  puts "   rails console"
  puts "   user = User.find_by(email: 'phanilkumar@gmail.com')"
  puts "   user.update!(locked_at: 11.minutes.ago)"
  puts "   exit"
  puts "3. **Test auto-unlock**:"
  puts "   curl -X POST http://localhost:3000/users/sign_in \\"
  puts "     -H 'Content-Type: application/json' \\"
  puts "     -d '{\"user\":{\"email\":\"phanilkumar@gmail.com\",\"password\":\"wrong\"}}'"
  puts "4. **Expected result**: 401 (Unauthorized) - account is unlocked"
  
  puts "\n💡 **Frontend Testing**:"
  puts "   Visit: http://localhost:3000/security/rate-limit-test"
  puts "   Use the 'Test 6 Attempts' button to lock account"
  puts "   Wait 10 minutes and try again"
end

# Run the test
test_auto_unlock
show_manual_test_instructions
