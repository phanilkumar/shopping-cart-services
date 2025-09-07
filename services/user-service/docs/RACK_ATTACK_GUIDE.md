# Rack Attack Configuration Guide

## Overview

This guide explains the Rack Attack configuration for the user-service, which provides rate limiting and security protection with environment-specific settings.

## Key Features

### Environment-Specific Configuration

- **Production**: Strict rate limits and comprehensive security measures
- **Development**: Relaxed limits (10x higher) for easier testing
- **Staging**: Production-like with slightly relaxed limits (2x)

### Rate Limiting

#### Authentication Endpoints
- Login: 5 attempts/20 seconds (production) | 50 attempts/2 seconds (development)
- Registration: 3 attempts/hour (production) | 30 attempts/6 minutes (development)  
- Password Reset: 3 attempts/hour (production) | 30 attempts/6 minutes (development)
- OTP: 5 attempts/hour (production) | 50 attempts/6 minutes (development)

#### API Endpoints
- General API: 100 requests/minute (production) | 1000 requests/6 seconds (development)
- Authenticated API: 300 requests/minute (production) | 3000 requests/6 seconds (development)

### Security Features

#### Attack Pattern Detection
- SQL Injection
- Cross-Site Scripting (XSS)
- Command Injection
- Path Traversal
- LDAP/NoSQL Injection
- Template Injection
- XML/XXE attacks

#### IP Management
- Automatic reputation tracking
- Dynamic blocking of repeat offenders
- Whitelisting for monitoring services
- Private network allowance in development

### Monitoring & Alerting

- Real-time statistics tracking
- Security incident logging
- Integration with monitoring services (Datadog, New Relic)
- Alert notifications (Slack, Email, PagerDuty)
- Admin dashboard for IP management

## Usage

### Testing Configuration
```bash
# Test the configuration
rake rack_attack:test

# View current statistics
rake rack_attack:stats

# Check specific IP reputation
rake rack_attack:check_ip[192.168.1.1]

# Simulate attacks (development only)
rake rack_attack:simulate_attacks
```

### Admin Dashboard
Access the Rack Attack dashboard at `/admin/rack_attack_dashboard` to:
- View current statistics
- Check IP reputations
- Whitelist/blacklist IPs
- Monitor security events

### Environment Variables

```bash
# Redis configuration (production)
REDIS_URL=redis://localhost:6379/1

# Monitoring services
SLACK_SECURITY_WEBHOOK=https://hooks.slack.com/...
SECURITY_EMAIL=security@example.com
PAGERDUTY_ROUTING_KEY=your-key

# Whitelisted IPs (comma-separated)
MONITORING_IPS=10.0.0.1,10.0.0.2

# Enable attack patterns in development
ENABLE_ATTACK_PATTERNS=true
```

## Customization

### Adding New Rate Limits
```ruby
throttle('custom_endpoint', 
  limit: PRODUCTION ? 10 : 100,
  period: PRODUCTION ? 1.minute : 6.seconds
) do |req|
  req.ip if req.path == '/custom/endpoint' && req.post?
end
```

### Adding New Attack Patterns
```ruby
attack_patterns += [
  /your_pattern_here/i
]
```

### Custom Monitoring
Extend the `RackAttackMonitor` class in `app/services/rack_attack_monitor.rb` to add custom monitoring logic.

## Troubleshooting

### Cache Store Issues
- Ensure Redis is running in production
- Check Redis connection with `rake rack_attack:test`
- Memory store is used in development by default

### False Positives
- Check logs for specific patterns that triggered blocks
- Use admin dashboard to whitelist legitimate IPs
- Adjust patterns if needed

### Performance Impact
- Monitor Redis memory usage
- Run cleanup task regularly: `rake rack_attack:cleanup`
- Consider adjusting cache expiration times

## Best Practices

1. **Regular Monitoring**: Check statistics daily in production
2. **IP Reputation**: Review suspicious IPs weekly
3. **Pattern Updates**: Keep attack patterns current
4. **Testing**: Test configuration changes in staging first
5. **Documentation**: Document any custom rules or exceptions

## Security Considerations

- Never disable attack patterns in production
- Keep monitoring webhooks/emails secure
- Regularly review and update security patterns
- Monitor for new attack vectors
- Coordinate with security team on incidents