# frozen_string_literal: true

# RackAttackMonitor provides monitoring and alerting capabilities for Rack::Attack
# This service integrates with various monitoring tools and provides insights
class RackAttackMonitor
  class << self
    # Track rate limit metrics
    def track_rate_limit(event_data)
      return unless Rails.env.production?

      discriminator = event_data[:match_discriminator]
      request = event_data[:request]
      
      # Track in Rails cache for dashboard
      increment_counter("rack_attack:throttled:#{discriminator}")
      increment_counter("rack_attack:throttled:total")
      
      # Track per IP
      track_ip_behavior(request.ip, :throttled, discriminator)
      
      # Send to monitoring service
      send_to_monitoring_service({
        event: 'rate_limit_hit',
        discriminator: discriminator,
        ip: request.ip,
        path: request.path,
        user_agent: request.user_agent
      })
    end

    # Track blocked requests
    def track_blocked_request(event_data)
      return unless Rails.env.production?

      discriminator = event_data[:match_discriminator]
      request = event_data[:request]
      
      # Track in Rails cache
      increment_counter("rack_attack:blocked:#{discriminator}")
      increment_counter("rack_attack:blocked:total")
      
      # Track per IP
      track_ip_behavior(request.ip, :blocked, discriminator)
      
      # Log security incident
      Rails.logger.error "[Security] Blocked request", {
        discriminator: discriminator,
        ip: request.ip,
        path: request.path,
        method: request.request_method,
        user_agent: request.user_agent,
        referrer: request.referrer
      }
      
      # Alert security team for certain patterns
      if should_alert?(discriminator)
        alert_security_team({
          severity: 'high',
          event: 'security_block',
          discriminator: discriminator,
          ip: request.ip,
          request_details: {
            path: request.path,
            method: request.request_method,
            user_agent: request.user_agent
          }
        })
      end
    end

    # Get current statistics
    def statistics
      {
        throttled: {
          total: get_counter("rack_attack:throttled:total"),
          by_rule: throttle_rules.map { |rule| 
            [rule, get_counter("rack_attack:throttled:#{rule}")]
          }.to_h
        },
        blocked: {
          total: get_counter("rack_attack:blocked:total"),
          by_rule: block_rules.map { |rule|
            [rule, get_counter("rack_attack:blocked:#{rule}")]
          }.to_h
        },
        suspicious_ips: get_suspicious_ips,
        time_window: '24_hours'
      }
    end

    # Check IP reputation
    def check_ip_reputation(ip)
      # Check internal tracking
      behavior = get_ip_behavior(ip)
      
      reputation_score = calculate_reputation_score(behavior)
      
      {
        ip: ip,
        reputation_score: reputation_score,
        throttle_count: behavior[:throttled_count] || 0,
        block_count: behavior[:blocked_count] || 0,
        last_seen: behavior[:last_seen],
        recommendation: get_recommendation(reputation_score)
      }
    end

    # Clean up old tracking data
    def cleanup_old_data
      # This should be run periodically (e.g., daily cron job)
      cleanup_expired_counters
      cleanup_old_ip_tracking
    end

    private

    def increment_counter(key)
      Rails.cache.increment(key, 1, expires_in: 24.hours)
    end

    def get_counter(key)
      Rails.cache.read(key).to_i
    end

    def track_ip_behavior(ip, action, discriminator)
      key = "rack_attack:ip_behavior:#{ip}"
      behavior = Rails.cache.read(key) || {}
      
      behavior[:last_seen] = Time.current
      behavior["#{action}_count"] = (behavior["#{action}_count"] || 0) + 1
      behavior[:recent_actions] ||= []
      behavior[:recent_actions] << {
        action: action,
        discriminator: discriminator,
        timestamp: Time.current
      }
      behavior[:recent_actions] = behavior[:recent_actions].last(100)
      
      Rails.cache.write(key, behavior, expires_in: 7.days)
    end

    def get_ip_behavior(ip)
      Rails.cache.read("rack_attack:ip_behavior:#{ip}") || {}
    end

    def calculate_reputation_score(behavior)
      # Simple scoring: 100 = good, 0 = bad
      score = 100
      score -= (behavior[:throttled_count] || 0) * 5
      score -= (behavior[:blocked_count] || 0) * 20
      score.clamp(0, 100)
    end

    def get_recommendation(score)
      case score
      when 80..100
        'trusted'
      when 60..79
        'monitor'
      when 40..59
        'restrict'
      when 0..39
        'block'
      end
    end

    def get_suspicious_ips
      # Get IPs with low reputation scores
      pattern = "rack_attack:ip_behavior:*"
      suspicious = []
      
      # Note: This is a simplified example. In production, use Redis SCAN
      # or maintain a separate index of IPs
      Rails.cache.instance_variable_get(:@data).keys.select { |k| k.match?(pattern) }.each do |key|
        ip = key.split(':').last
        behavior = Rails.cache.read(key)
        score = calculate_reputation_score(behavior)
        
        if score < 60
          suspicious << {
            ip: ip,
            score: score,
            throttled_count: behavior[:throttled_count] || 0,
            blocked_count: behavior[:blocked_count] || 0
          }
        end
      end
      
      suspicious.sort_by { |item| item[:score] }
    end

    def should_alert?(discriminator)
      # Alert for high-severity security blocks
      high_severity_patterns = %w[
        attack_patterns
        repeat_offenders
        sql_injection
        xss_attempt
        command_injection
      ]
      
      high_severity_patterns.any? { |pattern| discriminator.include?(pattern) }
    end

    def alert_security_team(alert_data)
      # Integrate with your alerting service
      # Examples: PagerDuty, Slack, Email, etc.
      
      # Slack webhook example
      if ENV['SLACK_SECURITY_WEBHOOK'].present?
        send_slack_alert(alert_data)
      end
      
      # Email example
      if ENV['SECURITY_EMAIL'].present?
        SecurityMailer.security_alert(alert_data).deliver_later
      end
      
      # PagerDuty example
      if ENV['PAGERDUTY_ROUTING_KEY'].present?
        send_pagerduty_alert(alert_data)
      end
    end

    def send_to_monitoring_service(data)
      # Send to your monitoring service (Datadog, New Relic, etc.)
      
      # Datadog example
      if defined?(Datadog::Statsd)
        statsd = Datadog::Statsd.new
        statsd.increment("rack_attack.#{data[:event]}", 
          tags: ["discriminator:#{data[:discriminator]}"])
      end
      
      # New Relic example
      if defined?(NewRelic::Agent)
        NewRelic::Agent.record_custom_event('RackAttackEvent', data)
      end
    end

    def send_slack_alert(alert_data)
      # Implement Slack webhook notification
      # This is a simplified example
      webhook_url = ENV['SLACK_SECURITY_WEBHOOK']
      
      message = {
        text: "🚨 Security Alert",
        attachments: [{
          color: "danger",
          title: "#{alert_data[:event].humanize}",
          fields: [
            { title: "IP Address", value: alert_data[:ip], short: true },
            { title: "Rule", value: alert_data[:discriminator], short: true },
            { title: "Path", value: alert_data.dig(:request_details, :path) },
            { title: "Method", value: alert_data.dig(:request_details, :method) },
            { title: "User Agent", value: alert_data.dig(:request_details, :user_agent) }
          ],
          footer: "Rack::Attack",
          ts: Time.current.to_i
        }]
      }
      
      # HTTParty.post(webhook_url, body: message.to_json, headers: { 'Content-Type' => 'application/json' })
    rescue => e
      Rails.logger.error "Failed to send Slack alert: #{e.message}"
    end

    def throttle_rules
      %w[
        login/ip login/email login/phone
        api_login/ip api_login/email api_login/phone
        register/ip register/email
        password_reset/ip password_reset/email
        otp/ip otp/phone
        api/ip api/authenticated
        exports/ip admin/ip
      ]
    end

    def block_rules
      %w[
        bad_user_agents
        repeat_offenders
        attack_patterns
      ]
    end

    def cleanup_expired_counters
      # Clean up counters older than 24 hours
      # Implementation depends on your cache store
    end

    def cleanup_old_ip_tracking
      # Clean up IP behavior data older than 7 days
      # Implementation depends on your cache store
    end
  end
end

# Subscribe to Rack::Attack events
ActiveSupport::Notifications.subscribe(/rack\.attack/) do |name, start, finish, request_id, payload|
  case payload[:match_type]
  when :throttle
    RackAttackMonitor.track_rate_limit(payload)
  when :blocklist
    RackAttackMonitor.track_blocked_request(payload)
  end
end