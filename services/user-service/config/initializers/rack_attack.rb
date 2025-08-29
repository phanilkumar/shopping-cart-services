# frozen_string_literal: true

class Rack::Attack
  # Configure Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" })

  # Rate limiting for login attempts
  throttle('login/ip', limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == '/api/v1/auth/login' && req.post?
  end

  # Rate limiting for OTP requests
  throttle('otp/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path == '/api/v1/auth/otp/send' && req.post?
  end

  # Rate limiting for registration
  throttle('register/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path == '/api/v1/auth/register' && req.post?
  end

  # Block suspicious requests
  blocklist('block suspicious requests') do |req|
    # Block requests with suspicious user agents
    suspicious_agents = [
      /bot/i,
      /crawler/i,
      /spider/i,
      /scraper/i,
      /curl/i,
      /wget/i
    ]
    
    suspicious_agents.any? { |pattern| req.user_agent&.match?(pattern) }
  end

  # Block requests from known malicious IPs (example)
  blocklist('block malicious IPs') do |req|
    # In production, you would maintain a list of known malicious IPs
    # This is just an example
    malicious_ips = []
    malicious_ips.include?(req.ip)
  end

  # Custom response for blocked requests
  self.blocklisted_response = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{error: 'Too many requests'}.to_json]]
  end

  # Custom response for throttled requests
  self.throttled_response = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{error: 'Rate limit exceeded'}.to_json]]
  end

  # Log blocked requests
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    if payload[:request].env['rack.attack.match_type'] == :blocklist
      Rails.logger.warn "Rack::Attack blocked request from #{payload[:request].ip}"
    end
  end
end
