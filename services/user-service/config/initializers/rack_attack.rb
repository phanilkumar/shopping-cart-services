# frozen_string_literal: true

# Enhanced Rack::Attack configuration with environment-specific settings
# Production: Strict security measures and rate limiting
# Development: Relaxed limits for easier testing and debugging

class Rack::Attack
  # Environment configuration
  PRODUCTION = Rails.env.production?
  DEVELOPMENT = Rails.env.development?
  STAGING = Rails.env.staging?

  # Configure cache store based on environment
  if PRODUCTION || STAGING
    # Use Redis for distributed caching in production/staging
    redis_config = {
      url: ENV['REDIS_URL'] || 'redis://localhost:6379/1',
      namespace: 'rack_attack',
      expires_in: 1.hour,
      pool_size: 5,
      pool_timeout: 5
    }
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(redis_config)
  else
    # Use memory store for development/test
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  # Environment-specific rate limit multipliers
  RATE_LIMIT_MULTIPLIER = DEVELOPMENT ? 10 : 1  # 10x more lenient in development
  TIME_PERIOD_DIVISOR = DEVELOPMENT ? 10 : 1    # 10x shorter periods in development

  # Safelist local development IPs
  if DEVELOPMENT
    safelist('allow-localhost') do |req|
      req.ip == '127.0.0.1' || req.ip == '::1' || req.ip == 'localhost'
    end

    # Allow all private network IPs in development
    safelist('allow-private-networks') do |req|
      IPAddr.new('10.0.0.0/8').include?(req.ip) ||
      IPAddr.new('172.16.0.0/12').include?(req.ip) ||
      IPAddr.new('192.168.0.0/16').include?(req.ip)
    end
  end

  # Production-only: Whitelist monitoring services
  if PRODUCTION
    safelist('allow-monitoring') do |req|
      # Add your monitoring service IPs here
      monitoring_ips = ENV.fetch('MONITORING_IPS', '').split(',').map(&:strip)
      monitoring_ips.include?(req.ip)
    end

    # Whitelist health check endpoints
    safelist('allow-health-checks') do |req|
      req.path.match?(/^\/(health|healthz|status|ping)$/)
    end
  end

  # === AUTHENTICATION RATE LIMITS ===
  
  # Login attempts per IP
  throttle('login/ip', 
    limit: PRODUCTION ? 5 : 50 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 20.seconds : 2.seconds) / TIME_PERIOD_DIVISOR
  ) do |req|
    req.ip if req.path == '/users/sign_in' && req.post?
  end

  # API login attempts per IP
  throttle('api_login/ip',
    limit: PRODUCTION ? 5 : 50 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 20.seconds : 2.seconds) / TIME_PERIOD_DIVISOR
  ) do |req|
    req.ip if req.path == '/api/v1/auth/login' && req.post?
  end

  # Registration attempts per IP
  throttle('register/ip',
    limit: PRODUCTION ? 3 : 30 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 1.hour : 6.minutes) / TIME_PERIOD_DIVISOR
  ) do |req|
    req.ip if req.path == '/users' && req.post?
  end

  # Password reset requests per IP
  throttle('password_reset/ip',
    limit: PRODUCTION ? 3 : 30 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 1.hour : 6.minutes) / TIME_PERIOD_DIVISOR
  ) do |req|
    req.ip if req.path == '/users/password' && req.post?
  end

  # OTP requests per IP
  throttle('otp/ip',
    limit: PRODUCTION ? 5 : 50 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 1.hour : 6.minutes) / TIME_PERIOD_DIVISOR
  ) do |req|
    req.ip if req.path.include?('/auth/otp/send') && req.post?
  end

  # === API RATE LIMITS ===
  
  # General API rate limiting per IP
  throttle('api/ip',
    limit: PRODUCTION ? 100 : 1000 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 1.minute : 6.seconds) / TIME_PERIOD_DIVISOR
  ) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Authenticated API rate limiting (more generous)
  throttle('api/authenticated',
    limit: PRODUCTION ? 300 : 3000 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 1.minute : 6.seconds) / TIME_PERIOD_DIVISOR
  ) do |req|
    if req.path.start_with?('/api/') && req.env['HTTP_AUTHORIZATION']
      # Extract user ID from JWT token if available
      begin
        token = req.env['HTTP_AUTHORIZATION'].split(' ').last
        # This is a simplified example - implement proper JWT decoding
        "user:#{req.ip}" # Fallback to IP if can't decode
      rescue
        nil
      end
    end
  end

  # Production-only: Strict rate limits for sensitive endpoints
  if PRODUCTION
    # Account enumeration prevention
    throttle('account_enumeration',
      limit: 10,
      period: 5.minutes
    ) do |req|
      req.ip if req.path.match?(/\/(users|api\/v1\/users)\/(check|exists|validate)/) && req.get?
    end

    # Export/Download rate limiting
    throttle('exports/ip',
      limit: 5,
      period: 1.hour
    ) do |req|
      req.ip if req.path.match?(/\/(export|download|reports)/)
    end

    # Admin panel access
    throttle('admin/ip',
      limit: 20,
      period: 1.minute
    ) do |req|
      req.ip if req.path.start_with?('/admin')
    end
  end

  # === SECURITY MEASURES ===

  # Block suspicious requests (production only)
  if PRODUCTION
    # Block requests with suspicious user agents
    blocklist('bad_user_agents') do |req|
      suspicious_agents = [
        /bot/i,
        /crawler/i,
        /spider/i,
        /scraper/i,
        /wget/i,
        /curl/i,
        /python-requests/i,
        /go-http-client/i,
        /java/i,
        /libwww-perl/i,
        /lwp-trivial/i,
        /httrack/i,
        /nutch/i,
        /phpunit/i,
        /sqlmap/i,
        /nikto/i,
        /scanner/i,
        /havij/i,
        /acunetix/i
      ]
      
      req.user_agent && suspicious_agents.any? { |pattern| req.user_agent.match?(pattern) }
    end

    # Dynamic IP blocking based on failed attempts
    blocklist('repeat_offenders') do |req|
      # Block IPs that have been throttled multiple times
      key = "repeat_offender:#{req.ip}"
      if Rack::Attack.cache.read(key).to_i > 10
        true
      else
        false
      end
    end
  end

  # Enhanced attack pattern detection (stricter in production)
  blocklist('attack_patterns') do |req|
    # Skip pattern checking in development unless explicitly enabled
    next false if DEVELOPMENT && ENV['ENABLE_ATTACK_PATTERNS'] != 'true'

    attack_patterns = [
      # SQL Injection
      /union.*select/i,
      /select.*from.*where/i,
      /insert.*into.*values/i,
      /update.*set.*where/i,
      /delete.*from.*where/i,
      /drop\s+(table|database)/i,
      /;.*--.*/,
      
      # XSS
      /<script[^>]*>/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /<iframe/i,
      /<object/i,
      /<embed/i,
      
      # Command Injection
      /;\s*(ls|cat|rm|mkdir|touch|chmod|chown)/i,
      /\|\s*(ls|cat|rm|mkdir|touch|chmod|chown)/i,
      /`.*`/,
      /\$\(.*\)/,
      
      # Path Traversal
      /\.\.\/|\.\.\\|%2e%2e/i,
      /\/etc\/passwd/i,
      /\/proc\/self/i,
      /C:\\.*\\system32/i,
      
      # LDAP Injection
      /\(\|\(/i,
      /\)\|\(/i,
      
      # NoSQL Injection
      /\$where/i,
      /\$ne/i,
      /\$gt/i,
      /\$regex/i,
      
      # XML/XXE
      /<!ENTITY/i,
      /<!DOCTYPE/i,
      /SYSTEM\s+"file:/i
    ]

    # Additional patterns for production
    if PRODUCTION
      attack_patterns += [
        # Advanced SQL Injection
        /benchmark\s*\(/i,
        /sleep\s*\(/i,
        /waitfor\s+delay/i,
        /pg_sleep/i,
        
        # Template Injection
        /\{\{.*\}\}/,
        /\{%.*%\}/,
        /<%.*%>/,
        /\${.*}/,
        
        # Header Injection
        /\r\n|\r|\n/,
        /%0d|%0a/i,
        
        # PHP Injection
        /php:\/\//i,
        /data:.*base64/i,
        /expect:\/\//i,
        
        # Advanced XSS
        /expression\s*\(/i,
        /import\s*\(/i,
        /vbscript:/i,
        /livescript:/i,
        /mocha:/i
      ]
    end

    # Check various parts of the request
    request_data = []
    request_data << req.path
    request_data << req.query_string if req.query_string.present?
    
    # Check request body
    if req.post? || req.put? || req.patch?
      begin
        body = req.body.read
        req.body.rewind
        request_data << body if body.present? && body.length < 10_000 # Limit body size to check
      rescue
        # Ignore body read errors
      end
    end
    
    # Check for attack patterns
    request_data.any? do |data|
      next false unless data.is_a?(String) && data.present?
      
      # Direct pattern matching
      if attack_patterns.any? { |pattern| data.match?(pattern) }
        Rails.logger.warn "[Rack::Attack] Attack pattern detected from #{req.ip}: #{data[0..200]}"
        
        # Track repeat offenders in production
        if PRODUCTION
          key = "repeat_offender:#{req.ip}"
          count = Rack::Attack.cache.read(key).to_i
          Rack::Attack.cache.write(key, count + 1, expires_in: 24.hours)
        end
        
        true
      else
        false
      end
    end
  end

  # === PER-USER RATE LIMITING ===

  # Login attempts per email
  throttle('login/email',
    limit: PRODUCTION ? 5 : 50 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 20.seconds : 2.seconds) / TIME_PERIOD_DIVISOR
  ) do |req|
    if req.path == '/users/sign_in' && req.post?
      email = extract_email_from_request(req, 'user')
      "login:email:#{email.downcase}" if email.present?
    end
  end

  # Login attempts per phone
  throttle('login/phone',
    limit: PRODUCTION ? 5 : 50 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 20.seconds : 2.seconds) / TIME_PERIOD_DIVISOR
  ) do |req|
    if req.path == '/users/sign_in' && req.post?
      phone = extract_phone_from_request(req, 'user')
      "login:phone:#{phone}" if phone.present?
    end
  end

  # API login attempts per email
  throttle('api_login/email',
    limit: PRODUCTION ? 5 : 50 * RATE_LIMIT_MULTIPLIER,
    period: (PRODUCTION ? 20.seconds : 2.seconds) / TIME_PERIOD_DIVISOR
  ) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      email = extract_email_from_request(req)
      "api_login:email:#{email.downcase}" if email.present?
    end
  end

  # === CUSTOM RESPONDERS ===

  # Throttled response
  self.throttled_responder = lambda do |env|
    matched = env['rack.attack.matched']
    now = Time.now.to_i
    
    # Calculate retry after based on the throttle period
    retry_after = if matched && env['rack.attack.match_data']
      match_data = env['rack.attack.match_data']
      period = match_data[:period] || 60
      period - (now % period)
    else
      60
    end

    headers = {
      'Content-Type' => 'application/json',
      'Retry-After' => retry_after.to_s,
      'X-RateLimit-Limit' => env['rack.attack.match_data'][:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => (now + retry_after).to_s
    }

    # Add CORS headers if needed
    headers['Access-Control-Allow-Origin'] = '*' if DEVELOPMENT

    body = {
      error: 'rate_limit_exceeded',
      message: 'Too many requests. Please try again later.',
      retry_after: retry_after
    }

    # Add debug info in development
    if DEVELOPMENT
      body[:debug] = {
        matched: matched,
        ip: env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR'],
        path: env['PATH_INFO']
      }
    end

    [429, headers, [body.to_json]]
  end

  # Blocked response
  self.blocklisted_responder = lambda do |env|
    headers = {
      'Content-Type' => 'application/json'
    }

    # Add CORS headers if needed
    headers['Access-Control-Allow-Origin'] = '*' if DEVELOPMENT

    body = {
      error: 'forbidden',
      message: 'Access denied due to security policy.'
    }

    # Add reason in development
    if DEVELOPMENT
      body[:reason] = env['rack.attack.matched']
      body[:ip] = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR']
    end

    # Log security incidents in production
    if PRODUCTION
      Rails.logger.error "[Rack::Attack] Blocked request from #{env['REMOTE_ADDR']}: #{env['rack.attack.matched']}"
    end

    [403, headers, [body.to_json]]
  end

  # === MONITORING AND LOGGING ===

  # Enhanced monitoring with environment-specific behavior
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    
    # Basic logging
    message = "[Rack::Attack] #{payload[:match_type]} - #{payload[:match_discriminator]}"
    details = {
      ip: req.ip,
      path: req.path,
      method: req.request_method,
      user_agent: req.user_agent
    }

    # Log level based on environment and type
    if PRODUCTION
      case payload[:match_type]
      when :blocklist
        Rails.logger.error message, details
        # Send to monitoring service
        notify_security_team(payload) if defined?(notify_security_team)
      when :throttle
        Rails.logger.warn message, details
        # Track metrics
        track_rate_limit_metric(payload) if defined?(track_rate_limit_metric)
      else
        Rails.logger.info message, details
      end
    else
      # More verbose logging in development
      Rails.logger.info message, details.merge(
        query_string: req.query_string,
        referrer: req.referrer,
        matched_data: payload[:match_data]
      )
    end

    # Production alerting
    if PRODUCTION && payload[:match_type] == :blocklist
      # Send to Sentry, Datadog, etc.
      if defined?(Sentry)
        Sentry.capture_message(
          "Security threat blocked",
          level: :warning,
          extra: details.merge(match: payload[:match_discriminator])
        )
      end
    end
  end

  # === HELPER METHODS ===

  class << self
    private

    def extract_email_from_request(req, wrapper = nil)
      body = read_request_body(req)
      return nil unless body

      parsed = JSON.parse(body)
      wrapper ? parsed.dig(wrapper, 'email') : parsed['email']
    rescue JSON::ParserError
      nil
    end

    def extract_phone_from_request(req, wrapper = nil)
      body = read_request_body(req)
      return nil unless body

      parsed = JSON.parse(body)
      wrapper ? parsed.dig(wrapper, 'phone') : parsed['phone']
    rescue JSON::ParserError
      nil
    end

    def read_request_body(req)
      body = req.body.read
      req.body.rewind
      body.presence
    rescue
      nil
    end
  end
end

# === OPTIONAL PRODUCTION ENHANCEMENTS ===

if defined?(Rails) && Rails.env.production?
  # Add custom middleware for additional security headers
  Rails.application.config.middleware.insert_before Rack::Attack, Rack::Protection::RemoteReferrer
  Rails.application.config.middleware.insert_before Rack::Attack, Rack::Protection::HttpOrigin

  # Enable additional security features
  Rails.application.config.force_ssl = true unless ENV['DISABLE_SSL'] == 'true'
end