# Rack::Attack configuration for rate limiting and security
class Rack::Attack
  # Use Redis for caching (fallback to memory if Redis is not available)
  cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')

  # Throttle login attempts by IP address
  throttle('login/ip', limit: 10, period: 15.minutes) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      req.ip
    end
  end

  # Throttle OTP requests by IP address
  throttle('otp/ip', limit: 5, period: 1.hour) do |req|
    if req.path == '/api/v1/auth/otp/send' && req.post?
      req.ip
    end
  end

  # Throttle registration attempts by IP address
  throttle('registration/ip', limit: 5, period: 1.hour) do |req|
    if req.path == '/api/v1/auth/register' && req.post?
      req.ip
    end
  end

  # Block suspicious user agents (disabled for testing)
  # blocklist('suspicious user agents') do |req|
  #   suspicious_agents = [
  #     'bot', 'crawler', 'spider', 'scraper',
  #     'python-requests', 'curl', 'wget',
  #     'Mozilla/5.0 (compatible; Googlebot',
  #     'Mozilla/5.0 (compatible; Bingbot'
  #   ]
  #   
  #   user_agent = req.user_agent.to_s.downcase
  #   suspicious_agents.any? { |agent| user_agent.include?(agent.downcase) }
  # end

  # Block malicious IPs (example - add your own)
  blocklist('malicious IPs') do |req|
    malicious_ips = [
      # Add known malicious IPs here
    ]
    
    malicious_ips.include?(req.ip)
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{
      status: 'error',
      message: 'Too many requests',
      errors: ['Rate limit exceeded. Please try again later.'],
      timestamp: Time.current.iso8601
    }.to_json]]
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{
      status: 'error',
      message: 'Too many requests',
      errors: ['Rate limit exceeded. Please try again later.'],
      timestamp: Time.current.iso8601
    }.to_json]]
  end

  # Log blocked requests
  blocklist('log blocked requests') do |req|
    Rails.logger.warn "Rack::Attack blocked request from #{req.ip}"
    false # Don't actually block, just log
  end
end
