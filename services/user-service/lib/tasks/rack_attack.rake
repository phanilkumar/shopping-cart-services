# frozen_string_literal: true

namespace :rack_attack do
  desc "Display current Rack::Attack statistics"
  task stats: :environment do
    stats = RackAttackMonitor.statistics
    
    puts "\n=== Rack::Attack Statistics ==="
    puts "Time Window: #{stats[:time_window]}"
    
    puts "\n--- Throttled Requests ---"
    puts "Total: #{stats[:throttled][:total]}"
    stats[:throttled][:by_rule].each do |rule, count|
      puts "  #{rule}: #{count}"
    end
    
    puts "\n--- Blocked Requests ---"
    puts "Total: #{stats[:blocked][:total]}"
    stats[:blocked][:by_rule].each do |rule, count|
      puts "  #{rule}: #{count}"
    end
    
    puts "\n--- Suspicious IPs ---"
    if stats[:suspicious_ips].any?
      stats[:suspicious_ips].first(10).each do |ip_data|
        puts "  #{ip_data[:ip]} - Score: #{ip_data[:score]}, " \
             "Throttled: #{ip_data[:throttled_count]}, " \
             "Blocked: #{ip_data[:blocked_count]}"
      end
    else
      puts "  None detected"
    end
  end

  desc "Check reputation for a specific IP"
  task :check_ip, [:ip] => :environment do |_t, args|
    ip = args[:ip]
    if ip.blank?
      puts "Usage: rake rack_attack:check_ip[IP_ADDRESS]"
      exit 1
    end

    reputation = RackAttackMonitor.check_ip_reputation(ip)
    
    puts "\n=== IP Reputation Check ==="
    puts "IP Address: #{reputation[:ip]}"
    puts "Reputation Score: #{reputation[:reputation_score]}/100"
    puts "Recommendation: #{reputation[:recommendation]}"
    puts "Throttle Count: #{reputation[:throttle_count]}"
    puts "Block Count: #{reputation[:block_count]}"
    puts "Last Seen: #{reputation[:last_seen] || 'Never'}"
  end

  desc "Clean up old Rack::Attack data"
  task cleanup: :environment do
    puts "Cleaning up old Rack::Attack data..."
    RackAttackMonitor.cleanup_old_data
    puts "Cleanup completed"
  end

  desc "Reset all Rack::Attack counters"
  task reset: :environment do
    print "Are you sure you want to reset all Rack::Attack counters? (y/N): "
    response = STDIN.gets.chomp.downcase
    
    if response == 'y'
      if Rails.env.production?
        puts "Cannot reset counters in production. Use cleanup task instead."
        exit 1
      end
      
      # Clear all rack attack keys from cache
      if Rails.cache.respond_to?(:delete_matched)
        Rails.cache.delete_matched("rack_attack:*")
      else
        puts "Cache store doesn't support delete_matched. Counters not reset."
      end
      
      puts "Rack::Attack counters reset"
    else
      puts "Reset cancelled"
    end
  end

  desc "Test Rack::Attack configuration"
  task test: :environment do
    puts "\n=== Testing Rack::Attack Configuration ==="
    
    # Test cache store
    print "Testing cache store... "
    begin
      Rack::Attack.cache.store.write("rack_attack:test", "test", expires_in: 1.second)
      if Rack::Attack.cache.store.read("rack_attack:test") == "test"
        puts "✓ OK"
      else
        puts "✗ FAILED"
      end
    rescue => e
      puts "✗ ERROR: #{e.message}"
    end
    
    # Test Redis connection (if using Redis)
    if Rails.env.production? || Rails.env.staging?
      print "Testing Redis connection... "
      begin
        redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/1'
        redis = Redis.new(url: redis_url)
        redis.ping
        puts "✓ OK"
      rescue => e
        puts "✗ ERROR: #{e.message}"
      end
    end
    
    # Display current configuration
    puts "\n--- Current Configuration ---"
    puts "Environment: #{Rails.env}"
    puts "Cache Store: #{Rack::Attack.cache.store.class}"
    puts "Rate Limit Multiplier: #{defined?(Rack::Attack::RATE_LIMIT_MULTIPLIER) ? Rack::Attack::RATE_LIMIT_MULTIPLIER : 1}"
    puts "Time Period Divisor: #{defined?(Rack::Attack::TIME_PERIOD_DIVISOR) ? Rack::Attack::TIME_PERIOD_DIVISOR : 1}"
    
    # Test a sample throttle
    print "\nTesting throttle mechanism... "
    begin
      test_key = "rack_attack:test_throttle"
      5.times { Rack::Attack.cache.count(test_key, 1.minute) }
      count = Rack::Attack.cache.read(test_key).to_i
      if count == 5
        puts "✓ OK (count: #{count})"
      else
        puts "✗ FAILED (expected: 5, got: #{count})"
      end
    rescue => e
      puts "✗ ERROR: #{e.message}"
    end
    
    puts "\nConfiguration test completed"
  end

  desc "Simulate attack patterns for testing"
  task simulate_attacks: :environment do
    if Rails.env.production?
      puts "Cannot run attack simulation in production!"
      exit 1
    end

    puts "\n=== Simulating Attack Patterns ==="
    puts "This will generate requests that should be blocked by Rack::Attack"
    
    require 'net/http'
    require 'uri'
    
    host = ENV['TEST_HOST'] || 'localhost:3000'
    
    attack_payloads = [
      { path: '/api/v1/users?id=1%20OR%201=1', description: 'SQL Injection' },
      { path: '/api/v1/users?name=<script>alert(1)</script>', description: 'XSS' },
      { path: '/api/v1/files?path=../../etc/passwd', description: 'Path Traversal' },
      { path: '/api/v1/exec?cmd=ls%20-la', description: 'Command Injection' }
    ]
    
    attack_payloads.each do |payload|
      print "Testing #{payload[:description]}... "
      
      begin
        uri = URI.parse("http://#{host}#{payload[:path]}")
        response = Net::HTTP.get_response(uri)
        
        if response.code == '403'
          puts "✓ Blocked (403)"
        else
          puts "✗ Not blocked (#{response.code})"
        end
      rescue => e
        puts "✗ Error: #{e.message}"
      end
      
      sleep 0.5
    end
    
    puts "\nAttack simulation completed"
  end

  desc "Export Rack::Attack configuration documentation"
  task docs: :environment do
    output_file = Rails.root.join('docs', 'rack_attack_configuration.md')
    FileUtils.mkdir_p(File.dirname(output_file))
    
    File.open(output_file, 'w') do |f|
      f.puts "# Rack::Attack Configuration Documentation"
      f.puts "\nGenerated on: #{Time.current}"
      f.puts "\n## Environment: #{Rails.env}"
      
      f.puts "\n## Rate Limits"
      f.puts "\n### Authentication Endpoints"
      f.puts "- **Login**: 5 attempts per 20 seconds (per IP/email/phone)"
      f.puts "- **Registration**: 3 attempts per hour (per IP/email)"
      f.puts "- **Password Reset**: 3 attempts per hour (per IP/email)"
      f.puts "- **OTP**: 5 attempts per hour (per IP/phone)"
      
      f.puts "\n### API Endpoints"
      f.puts "- **General API**: 100 requests per minute (per IP)"
      f.puts "- **Authenticated API**: 300 requests per minute (per user)"
      
      if Rails.env.production?
        f.puts "\n### Additional Production Limits"
        f.puts "- **Account Enumeration**: 10 attempts per 5 minutes"
        f.puts "- **Exports**: 5 requests per hour"
        f.puts "- **Admin Panel**: 20 requests per minute"
      end
      
      f.puts "\n## Security Patterns Blocked"
      f.puts "- SQL Injection attempts"
      f.puts "- Cross-Site Scripting (XSS)"
      f.puts "- Command Injection"
      f.puts "- Path Traversal"
      f.puts "- LDAP Injection"
      f.puts "- NoSQL Injection"
      f.puts "- Template Injection"
      f.puts "- XML/XXE attacks"
      
      f.puts "\n## Monitoring"
      f.puts "- All rate limit hits are logged"
      f.puts "- Security blocks trigger alerts in production"
      f.puts "- IP reputation tracking enabled"
      f.puts "- Statistics available via admin dashboard"
      
      f.puts "\n## Testing"
      f.puts "```bash"
      f.puts "# Check statistics"
      f.puts "rake rack_attack:stats"
      f.puts ""
      f.puts "# Check specific IP"
      f.puts "rake rack_attack:check_ip[192.168.1.1]"
      f.puts ""
      f.puts "# Test configuration"
      f.puts "rake rack_attack:test"
      f.puts "```"
    end
    
    puts "Documentation exported to: #{output_file}"
  end
end