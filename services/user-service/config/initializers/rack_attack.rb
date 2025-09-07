# frozen_string_literal: true

# Clean Rack::Attack configuration for testing rate limiting functionality
# This version focuses only on rate limiting without aggressive pattern detection

class Rack::Attack
  # Configure Rack::Attack cache store
  if Rails.env.production?
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')
  else
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  # Safety wrapper to handle nil requests
  def self.safe_req_check(req)
    return false unless req
    return false unless req.respond_to?(:path)
    return false unless req.respond_to?(:ip)
    return false unless req.respond_to?(:post?)
    return false unless req.respond_to?(:get?)
    return false unless req.respond_to?(:user_agent)
    true
  end

  # Rate limiting for login attempts (Devise) - Allow more attempts to let account lockout work
  throttle('login/ip', limit: 10, period: 1.minute) do |req|
    next unless safe_req_check(req)
    req.ip if (req.path == '/users/sign_in' && req.post?) || 
              (req.path == '/login' && req.post?) ||
              (req.path == '/api/v1/auth/login' && req.post?)
  end

  # Rate limiting for API login attempts (separate for API-specific limits)
  throttle('api_login/ip', limit: 5, period: 20.seconds) do |req|
    next unless safe_req_check(req)
    req.ip if req.path == '/api/v1/auth/login' && req.post?
  end

  # Rate limiting for registration attempts
  throttle('register/ip', limit: 3, period: 1.hour) do |req|
    next unless safe_req_check(req)
    req.ip if req.path == '/users' && req.post?
  end

  # Rate limiting for password reset requests
  throttle('password_reset/ip', limit: 3, period: 1.hour) do |req|
    next unless safe_req_check(req)
    req.ip if req.path == '/users/password' && req.post?
  end

  # Rate limiting for OTP requests
  throttle('otp/ip', limit: 5, period: 1.hour) do |req|
    next unless safe_req_check(req)
    req.ip if req.path&.include?('/auth/otp/send') && req.post?
  end

  # Rate limiting for API endpoints
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    next unless safe_req_check(req)
    req.ip if req.path&.start_with?('/api/')
  end

  # Rate limiting for security dashboard access
  throttle('security/ip', limit: 20, period: 1.minute) do |req|
    next unless safe_req_check(req)
    req.ip if req.path == '/security' && req.get?
  end

  # Block suspicious IPs (example: too many failed attempts)
  blocklist('blocklist/ip') do |req|
    next unless safe_req_check(req)
    # This would typically be populated by your application logic
    # For now, we'll use a simple example
    false
  end

  # Block requests with suspicious user agents
  blocklist('blocklist/user_agent') do |req|
    next unless safe_req_check(req)
    req.user_agent && (
      req.user_agent.include?('bot') ||
      req.user_agent.include?('crawler') ||
      req.user_agent.include?('spider') ||
      req.user_agent.include?('scraper')
    )
  end

  # Block requests with suspicious patterns
  blocklist('blocklist/suspicious_patterns') do |req|
    next unless safe_req_check(req)
    # Comprehensive attack pattern detection - only check user input, not system headers
    attack_patterns = [
      # SQL Injection Patterns
      /union\s+select/i,
      /drop\s+table/i,
      /insert\s+into/i,
      /delete\s+from/i,
      /update\s+set/i,
      
      # Boolean-based SQL Injection
      /OR\s*['"]1['"]\s*=\s*['"]1['"]/i,
      /\s+OR\s+1\s*=\s*1/i,
      /AND\s*1\s*=\s*1/i,
      /OR\s*true/i,
      /AND\s*true/i,
      
      # Time-based SQL Injection
      /sleep\s*\(/i,
      /waitfor\s+delay/i,
      /benchmark\s*\(/i,
      
      # Code Execution Patterns
      /exec\s*\(/i,
      /eval\s*\(/i,
      /system\s*\(/i,
      /`.*`/i,
      /\$\(.*\)/i,
      
      # Command Injection Patterns
      /;\s*(rm|ls|cat|pwd|whoami|id|uname)/i,
      /\|\s*(rm|ls|cat|pwd|whoami|id|uname)/i,
      /&&\s*(rm|ls|cat|pwd|whoami|id|uname)/i,
      
      # XSS Patterns
      /<script[^>]*>/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /vbscript:/i,
      /data:text\/html/i,
      
      # Advanced XSS
      /expression\s*\(/i,
      /url\s*\(/i,
      /import\s*\(/i,
      /@import/i,
      
      # NoSQL Injection
      /\$where/i,
      /\$ne/i,
      /\$gt/i,
      /\$lt/i,
      /\$regex/i,
      
      # LDAP Injection
      /\*\)/i,
      /\(\|/i,
      /\(\&/i,
      
      # Path Traversal
      /\.\.\//i,
      /\.\.\\/i,
      /%2e%2e%2f/i,
      /%2e%2e%5c/i,
      
      # File Inclusion
      /include\s*\(/i,
      /require\s*\(/i,
      /include_once/i,
      /require_once/i,
      
      # Template Injection
      /\{\{.*\}\}/i,
      /\{%.*%\}/i,
      /<%.*%>/i,
      
      # XML Injection
      /<!\[CDATA\[/i,
      /<\!ENTITY/i,
      /<\!DOCTYPE/i,
      
      # Header Injection
      /%0d%0a/i,
      /%0a/i,
      /%0d/i,
      
      # Encoding Bypass
      /%3cscript/i,
      /%3c%73%63%72%69%70%74/i,
      /&#x3c;script/i,
      /&#60;script/i
    ]

    # Enhanced request data collection and analysis - ONLY user input
    request_data = []
    
    # Check path
    request_data << (req.path || 'unknown')
    
    # Check query string (URL decoded)
    if req.query_string.present?
      request_data << URI.decode_www_form_component(req.query_string)
    end
    
    # Check request body for POST requests
    if req.post?
      begin
        body = req.body.read
        req.body.rewind  # Reset body for later reading
        request_data << body if body.present?
      rescue
        # Ignore parsing errors
      end
    end
    
    # Only check specific user input headers, NOT system headers
    user_input_headers = ['HTTP_X_FORWARDED_FOR', 'HTTP_X_REAL_IP', 'HTTP_REFERER']
    user_input_headers.each do |header|
      if req.env[header].present?
        request_data << req.env[header]
      end
    end
    
    # Multi-stage pattern detection
    detected = false
    
    request_data.each do |data|
      next unless data.is_a?(String) && data.present?
      
      # Skip system headers and common browser data
      next if data.match?(/^(gzip|deflate|identity|text\/|application\/|image\/|audio\/|video\/|Mozilla\/|AppleWebKit|Chrome|Safari|Firefox|Edge)/i)
      next if data.match?(/^(en-US|en-GB|en;q=|keep-alive|close|utf-8|ISO-8859)/i)
      next if data.match?(/^(\*\/\*|q=0\.|Accept|User-Agent|Connection|Host)/i)
      
      # Stage 1: Direct pattern matching
      if attack_patterns.any? { |pattern| data.match?(pattern) }
        Rails.logger.warn "Rack::Attack: Pattern detected in request data: #{data[0..100]}"
        detected = true
        break
      end
      
      # Stage 2: URL decoding check
      begin
        decoded_data = URI.decode_www_form_component(data)
        if decoded_data != data && attack_patterns.any? { |pattern| decoded_data.match?(pattern) }
          Rails.logger.warn "Rack::Attack: Pattern detected in decoded data: #{decoded_data[0..100]}"
          detected = true
          break
        end
      rescue
        # Ignore decoding errors
      end
      
      # Stage 3: HTML entity decoding check
      begin
        html_decoded = data.gsub(/&#x([0-9a-f]+);/i) { [$1.hex].pack('U') }
                           .gsub(/&#(\d+);/) { [$1.to_i].pack('U') }
        if html_decoded != data && attack_patterns.any? { |pattern| html_decoded.match?(pattern) }
          Rails.logger.warn "Rack::Attack: Pattern detected in HTML decoded data: #{html_decoded[0..100]}"
          detected = true
          break
        end
      rescue
        # Ignore decoding errors
      end
    end
    
    detected
  end

  # Custom throttling for failed login attempts per email
  throttle('login/email', limit: 5, period: 20.seconds) do |req|
    next unless safe_req_check(req)
    if req.path == '/users/sign_in' && req.post?
      # Extract email from request body
      begin
        body = req.body.read
        req.body.rewind
        if body.present?
          parsed_body = JSON.parse(body)
          email = parsed_body.dig('user', 'email')
          email if email.present?
        end
      rescue
        # Ignore parsing errors
      end
    end
  end

  # Custom throttling for failed login attempts per phone
  throttle('login/phone', limit: 5, period: 20.seconds) do |req|
    next unless safe_req_check(req)
    if req.path == '/users/sign_in' && req.post?
      # Extract phone from request body
      begin
        body = req.body.read
        req.body.rewind
        if body.present?
          parsed_body = JSON.parse(body)
          phone = parsed_body.dig('user', 'phone')
          phone if phone.present?
        end
      rescue
        # Ignore parsing errors
      end
    end
  end

  # Custom throttling for failed API login attempts per email
  throttle('api_login/email', limit: 5, period: 20.seconds) do |req|
    next unless safe_req_check(req)
    if req.path == '/api/v1/auth/login' && req.post?
      # Extract email from request body
      begin
        body = req.body.read
        req.body.rewind
        if body.present?
          parsed_body = JSON.parse(body)
          email = parsed_body['email']
          email if email.present?
        end
      rescue
        # Ignore parsing errors
      end
    end
  end

  # Custom throttling for failed API login attempts per phone
  throttle('api_login/phone', limit: 5, period: 20.seconds) do |req|
    next unless safe_req_check(req)
    if req.path == '/api/v1/auth/login' && req.post?
      # Extract phone from request body
      begin
        body = req.body.read
        req.body.rewind
        if body.present?
          parsed_body = JSON.parse(body)
          phone = parsed_body['phone']
          phone if phone.present?
        end
      rescue
        # Ignore parsing errors
      end
    end
  end

  # Custom throttling for registration attempts per email
  throttle('register/email', limit: 3, period: 1.hour) do |req|
    next unless safe_req_check(req)
    if req.path == '/users' && req.post?
      # Extract email from request body
      begin
        body = req.body.read
        req.body.rewind
        if body.present?
          parsed_body = JSON.parse(body)
          email = parsed_body.dig('user', 'email')
          email if email.present?
        end
      rescue
        # Ignore parsing errors
      end
    end
  end

  # Custom throttling for password reset attempts per email
  throttle('password_reset/email', limit: 3, period: 1.hour) do |req|
    next unless safe_req_check(req)
    if req.path == '/users/password' && req.post?
      # Extract email from request body
      begin
        body = req.body.read
        req.body.rewind
        if body.present?
          parsed_body = JSON.parse(body)
          email = parsed_body.dig('user', 'email')
          email if email.present?
        end
      rescue
        # Ignore parsing errors
      end
    end
  end

  # Custom throttling for OTP attempts per phone
  throttle('otp/phone', limit: 5, period: 1.hour) do |req|
    next unless safe_req_check(req)
    if req.path&.include?('/auth/otp/send') && req.post?
      # Extract phone from request body
      begin
        body = req.body.read
        req.body.rewind
        if body.present?
          parsed_body = JSON.parse(body)
          phone = parsed_body['phone']
          phone if phone.present?
        end
      rescue
        # Ignore parsing errors
      end
    end
  end

  # Configure response for throttled requests
  self.throttled_responder = lambda do |request|
    # Extract rate limit info from the matched throttle
    env = request.env if request.respond_to?(:env)
    env ||= request
    
    match_data = env['rack.attack.match_data'] if env.respond_to?(:[])
    now = Time.now.to_i
    
    # Set default values if match_data is not available
    limit = match_data.is_a?(Hash) ? (match_data[:limit] || 100) : 100
    period = match_data.is_a?(Hash) ? (match_data[:period] || 60) : 60
    
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => '20',
        'X-RateLimit-Limit' => limit.to_s,
        'X-RateLimit-Remaining' => '0',
        'X-RateLimit-Reset' => (now + period).to_s
      },
      [{
        error: 'Too many requests',
        message: 'Rate limit exceeded. Please try again later.',
        retry_after: 20
      }.to_json]
    ]
  end

  # Configure response for blocked requests
  self.blocklisted_responder = lambda do |env|
    [
      403,
      {
        'Content-Type' => 'application/json'
      },
      [{
        error: 'Forbidden',
        message: 'Access denied due to security policy.'
      }.to_json]
    ]
  end

  # Enhanced logging and monitoring - temporarily disabled to fix nil error
  # ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
  #   begin
  #     req = payload[:request]
  #     match_discriminator = payload[:match_discriminator]
  #     
  #     # Safe logging with nil checks
  #     discriminator_text = match_discriminator || 'unknown'
  #     ip_address = req&.ip || 'unknown'
  #     path = req&.path || 'unknown'
  #     user_agent = req&.user_agent || 'unknown'
  #     
  #     Rails.logger.warn "Rack::Attack: #{discriminator_text} - IP: #{ip_address}, Path: #{path}, User-Agent: #{user_agent}"
  #     
  #     # You could also send this to your monitoring service
  #     # Sentry.capture_message("Rack::Attack: #{discriminator_text}", level: :warning) if defined?(Sentry)
  #     
  #     # Log additional context for security analysis with safe nil checking
  #     if match_discriminator && match_discriminator.is_a?(String) && match_discriminator.include?('blocklist')
  #       Rails.logger.warn "Rack::Attack: Security threat detected - #{match_discriminator}"
  #     end
  #   rescue => e
  #     Rails.logger.error "Rack::Attack logging error: #{e.message}"
  #     Rails.logger.error "Payload: #{payload.inspect}"
  #   end
  # end
end 