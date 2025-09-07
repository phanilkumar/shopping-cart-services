#!/usr/bin/env ruby
# frozen_string_literal: true

# Rate Limiting & Brute Force Protection Test Script
# This script provides comprehensive testing for rate limiting features

require 'net/http'
require 'json'
require 'uri'
require 'time'

class RateLimitingTester
  def initialize(base_url = 'http://localhost:3000')
    @base_url = base_url
    @results = []
  end

  def run_all_tests
    puts "🚀 Starting Rate Limiting & Brute Force Protection Tests"
    puts "=" * 60
    
    test_login_rate_limiting
    test_api_rate_limiting
    test_registration_rate_limiting
    test_password_reset_rate_limiting
    test_otp_rate_limiting
    test_security_dashboard_rate_limiting
    test_attack_pattern_blocking
    test_user_agent_blocking
    test_rate_limit_headers
    test_rate_limit_reset
    
    print_summary
  end

  private

  def test_login_rate_limiting
    puts "\n🔐 Testing Login Rate Limiting (5 attempts per 20 seconds)"
    puts "-" * 50
    
    endpoint = '/users/sign_in'
    limit = 5
    success_count = 0
    rate_limited = false
    
    (limit + 2).times do |i|
      response = make_request(:post, endpoint, {
        user: { email: 'test@example.com', password: 'wrong' }
      })
      
      if response[:status] == 401
        success_count += 1
        puts "  Attempt #{i + 1}: ✅ 401 (Unauthorized - expected)"
      elsif response[:status] == 429
        rate_limited = true
        puts "  Attempt #{i + 1}: 🚫 429 (Rate Limited)"
        break
      else
        puts "  Attempt #{i + 1}: ❌ #{response[:status]} (Unexpected)"
      end
      
      sleep(0.5) # Small delay between requests
    end
    
    result = {
      test: 'Login Rate Limiting',
      passed: rate_limited && success_count == limit,
      details: "Successfully made #{success_count} requests before rate limiting"
    }
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def test_api_rate_limiting
    puts "\n🌐 Testing API Rate Limiting (100 requests per minute)"
    puts "-" * 50
    
    endpoint = '/api/v1/users/1'
    limit = 100
    success_count = 0
    rate_limited = false
    
    (limit + 5).times do |i|
      response = make_request(:get, endpoint)
      
      if response[:status] != 429
        success_count += 1
        if i < 10 || i % 20 == 0
          puts "  Request #{i + 1}: ✅ #{response[:status]}"
        end
      else
        rate_limited = true
        puts "  Request #{i + 1}: 🚫 429 (Rate Limited)"
        break
      end
      
      sleep(0.1) # Small delay between requests
    end
    
    result = {
      test: 'API Rate Limiting',
      passed: rate_limited && success_count >= limit,
      details: "Successfully made #{success_count} requests before rate limiting"
    }
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def test_registration_rate_limiting
    puts "\n📝 Testing Registration Rate Limiting (3 attempts per hour)"
    puts "-" * 50
    
    endpoint = '/users'
    limit = 3
    success_count = 0
    rate_limited = false
    
    (limit + 2).times do |i|
      response = make_request(:post, endpoint, {
        user: { 
          email: "test#{i}@example.com", 
          password: 'password123',
          password_confirmation: 'password123'
        }
      })
      
      if response[:status] != 429
        success_count += 1
        puts "  Attempt #{i + 1}: ✅ #{response[:status]}"
      else
        rate_limited = true
        puts "  Attempt #{i + 1}: 🚫 429 (Rate Limited)"
        break
      end
      
      sleep(0.5)
    end
    
    result = {
      test: 'Registration Rate Limiting',
      passed: rate_limited && success_count == limit,
      details: "Successfully made #{success_count} requests before rate limiting"
    }
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def test_password_reset_rate_limiting
    puts "\n🔑 Testing Password Reset Rate Limiting (3 attempts per hour)"
    puts "-" * 50
    
    endpoint = '/users/password'
    limit = 3
    success_count = 0
    rate_limited = false
    
    (limit + 2).times do |i|
      response = make_request(:post, endpoint, {
        user: { email: "test#{i}@example.com" }
      })
      
      if response[:status] != 429
        success_count += 1
        puts "  Attempt #{i + 1}: ✅ #{response[:status]}"
      else
        rate_limited = true
        puts "  Attempt #{i + 1}: 🚫 429 (Rate Limited)"
        break
      end
      
      sleep(0.5)
    end
    
    result = {
      test: 'Password Reset Rate Limiting',
      passed: rate_limited && success_count == limit,
      details: "Successfully made #{success_count} requests before rate limiting"
    }
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def test_otp_rate_limiting
    puts "\n📱 Testing OTP Rate Limiting (5 attempts per hour)"
    puts "-" * 50
    
    endpoint = '/auth/otp/send'
    limit = 5
    success_count = 0
    rate_limited = false
    
    (limit + 2).times do |i|
      response = make_request(:post, endpoint, {
        phone: "+123456789#{i}"
      })
      
      if response[:status] != 429
        success_count += 1
        puts "  Attempt #{i + 1}: ✅ #{response[:status]}"
      else
        rate_limited = true
        puts "  Attempt #{i + 1}: 🚫 429 (Rate Limited)"
        break
      end
      
      sleep(0.5)
    end
    
    result = {
      test: 'OTP Rate Limiting',
      passed: rate_limited && success_count == limit,
      details: "Successfully made #{success_count} requests before rate limiting"
    }
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def test_security_dashboard_rate_limiting
    puts "\n🛡️ Testing Security Dashboard Rate Limiting (20 requests per minute)"
    puts "-" * 50
    
    endpoint = '/security'
    limit = 20
    success_count = 0
    rate_limited = false
    
    (limit + 3).times do |i|
      response = make_request(:get, endpoint)
      
      if response[:status] != 429
        success_count += 1
        if i < 5 || i % 5 == 0
          puts "  Request #{i + 1}: ✅ #{response[:status]}"
        end
      else
        rate_limited = true
        puts "  Request #{i + 1}: 🚫 429 (Rate Limited)"
        break
      end
      
      sleep(0.2)
    end
    
    result = {
      test: 'Security Dashboard Rate Limiting',
      passed: rate_limited && success_count >= limit,
      details: "Successfully made #{success_count} requests before rate limiting"
    }
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def test_attack_pattern_blocking
    puts "\n🚨 Testing Attack Pattern Blocking"
    puts "-" * 50
    
    attack_patterns = [
      { name: 'SQL Injection', url: '/api/v1/users?id=1 OR 1=1' },
      { name: 'XSS Attack', url: '/api/v1/users?name=<script>alert(1)</script>' },
      { name: 'Path Traversal', url: '/api/v1/files?path=../../etc/passwd' },
      { name: 'Command Injection', url: '/api/v1/users?cmd=;rm -rf /' }
    ]
    
    blocked_count = 0
    
    attack_patterns.each do |pattern|
      response = make_request(:get, pattern[:url])
      
      if response[:status] == 403
        puts "  #{pattern[:name]}: ✅ 403 (Blocked)"
        blocked_count += 1
      else
        puts "  #{pattern[:name]}: ❌ #{response[:status]} (Not Blocked)"
      end
    end
    
    result = {
      test: 'Attack Pattern Blocking',
      passed: blocked_count == attack_patterns.length,
      details: "Blocked #{blocked_count}/#{attack_patterns.length} attack patterns"
    }
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def test_user_agent_blocking
    puts "\n🤖 Testing User Agent Blocking"
    puts "-" * 50
    
    user_agents = [
      { name: 'Normal Browser', agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', should_block: false },
      { name: 'Bot User Agent', agent: 'sqlmap/1.0', should_block: true },
      { name: 'Crawler', agent: 'Googlebot/2.1', should_block: true },
      { name: 'Spider', agent: 'SpiderBot/1.0', should_block: true }
    ]
    
    correct_blocks = 0
    
    user_agents.each do |ua|
      response = make_request(:get, '/', {}, { 'User-Agent' => ua[:agent] })
      
      if (response[:status] == 403) == ua[:should_block]
        puts "  #{ua[:name]}: ✅ #{response[:status]} (#{ua[:should_block] ? 'Blocked' : 'Allowed'})"
        correct_blocks += 1
      else
        puts "  #{ua[:name]}: ❌ #{response[:status]} (Expected #{ua[:should_block] ? '403' : 'not 403'})"
      end
    end
    
    result = {
      test: 'User Agent Blocking',
      passed: correct_blocks == user_agents.length,
      details: "Correctly handled #{correct_blocks}/#{user_agents.length} user agents"
    }
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def test_rate_limit_headers
    puts "\n📋 Testing Rate Limit Headers"
    puts "-" * 50
    
    # First, trigger rate limiting
    endpoint = '/api/v1/users/1'
    105.times { make_request(:get, endpoint) }
    
    # Check the rate limited response
    response = make_request(:get, endpoint)
    
    expected_headers = ['Retry-After', 'X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset']
    found_headers = 0
    
    expected_headers.each do |header|
      if response[:headers][header.downcase]
        puts "  #{header}: ✅ #{response[:headers][header.downcase]}"
        found_headers += 1
      else
        puts "  #{header}: ❌ Missing"
      end
    end
    
    result = {
      test: 'Rate Limit Headers',
      passed: found_headers == expected_headers.length,
      details: "Found #{found_headers}/#{expected_headers.length} expected headers"
    }
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def test_rate_limit_reset
    puts "\n⏰ Testing Rate Limit Reset (simulated)"
    puts "-" * 50
    
    endpoint = '/api/v1/users/1'
    
    # Trigger rate limiting
    105.times { make_request(:get, endpoint) }
    
    # Check if rate limited
    response = make_request(:get, endpoint)
    if response[:status] == 429
      puts "  Rate limiting triggered: ✅"
      
      # In a real scenario, you would wait for the reset period
      # For testing, we'll just verify the retry-after header
      retry_after = response[:headers]['retry-after']
      if retry_after
        puts "  Retry-After header: ✅ #{retry_after} seconds"
        result = { test: 'Rate Limit Reset', passed: true, details: "Retry-After header present: #{retry_after}s" }
      else
        puts "  Retry-After header: ❌ Missing"
        result = { test: 'Rate Limit Reset', passed: false, details: "Retry-After header missing" }
      end
    else
      puts "  Rate limiting not triggered: ❌"
      result = { test: 'Rate Limit Reset', passed: false, details: "Rate limiting not triggered" }
    end
    
    @results << result
    puts "  Result: #{result[:passed] ? '✅ PASSED' : '❌ FAILED'}"
  end

  def make_request(method, path, body = nil, headers = {})
    uri = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10
    
    case method
    when :get
      request = Net::HTTP::Get.new(uri)
    when :post
      request = Net::HTTP::Post.new(uri)
      request.body = body.to_json if body
      request['Content-Type'] = 'application/json'
    end
    
    # Add custom headers
    headers.each { |key, value| request[key] = value }
    
    begin
      response = http.request(request)
      {
        status: response.code.to_i,
        body: response.body,
        headers: response.to_hash
      }
    rescue => e
      {
        status: 0,
        body: e.message,
        headers: {}
      }
    end
  end

  def print_summary
    puts "\n" + "=" * 60
    puts "📊 TEST SUMMARY"
    puts "=" * 60
    
    passed = @results.count { |r| r[:passed] }
    total = @results.length
    
    puts "Total Tests: #{total}"
    puts "Passed: #{passed}"
    puts "Failed: #{total - passed}"
    puts "Success Rate: #{(passed.to_f / total * 100).round(1)}%"
    
    puts "\nDetailed Results:"
    @results.each do |result|
      status = result[:passed] ? '✅ PASSED' : '❌ FAILED'
      puts "  #{status} - #{result[:test]}: #{result[:details]}"
    end
    
    if passed == total
      puts "\n🎉 All tests passed! Rate limiting is working correctly."
    else
      puts "\n⚠️  Some tests failed. Please review the configuration."
    end
  end
end

# Run the tests if this script is executed directly
if __FILE__ == $0
  base_url = ARGV[0] || 'http://localhost:3000'
  tester = RateLimitingTester.new(base_url)
  tester.run_all_tests
end
