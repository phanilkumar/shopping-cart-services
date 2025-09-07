# Rate Limiting & Brute Force Protection - Testing Summary

## 🎯 Overview

This document provides a comprehensive guide for testing Rate Limiting & Brute Force Protection features in the User Service. The system uses Rack::Attack to implement various security measures.

## 📋 Available Testing Methods

### 1. **Automated RSpec Tests** ✅
```bash
# Run all rate limiting tests
bundle exec rspec spec/initializers/rack_attack_spec.rb

# Run specific test groups
bundle exec rspec spec/initializers/rack_attack_spec.rb -e "rate limiting"
bundle exec rspec spec/initializers/rack_attack_spec.rb -e "security blocking"
```

**What it tests:**
- Login rate limiting (5 attempts per 20 seconds)
- API rate limiting (100 requests per minute)
- Attack pattern blocking (SQL injection, XSS, path traversal)
- User agent blocking
- Rate limit headers
- Response format validation

### 2. **Ruby Test Script** ✅
```bash
# Run comprehensive test script
ruby test_rate_limiting.rb

# Run with custom URL
ruby test_rate_limiting.rb http://localhost:3000
```

**What it tests:**
- All rate limiting endpoints
- Attack pattern detection
- User agent blocking
- Rate limit headers
- Rate limit reset functionality
- Detailed reporting with pass/fail status

### 3. **Shell Script Testing** ✅
```bash
# Run quick shell-based tests
./test_rate_limiting.sh
```

**What it tests:**
- Basic rate limiting functionality
- Attack pattern blocking
- User agent blocking
- Rate limit headers
- Quick validation of core features

### 4. **Manual cURL Testing** ✅
```bash
# Test login rate limiting
for i in {1..7}; do
  curl -X POST http://localhost:3000/users/sign_in \
    -H "Content-Type: application/json" \
    -d '{"user":{"email":"test@example.com","password":"wrong"}}' \
    -w "Status: %{http_code}\n" -s
  sleep 1
done

# Test API rate limiting
for i in {1..105}; do
  curl -X GET http://localhost:3000/api/v1/users/1 \
    -w "Status: %{http_code}\n" -s
  if [ $((i % 20)) -eq 0 ]; then echo "--- $i requests completed ---"; fi
done
```

## 🔧 Current Rate Limiting Configuration

| Endpoint | Method | Limit | Period | Purpose |
|----------|--------|-------|--------|---------|
| `/users/sign_in` | POST | 5 | 20 seconds | Login brute force protection |
| `/api/v1/auth/login` | POST | 5 | 20 seconds | API login protection |
| `/users` | POST | 3 | 1 hour | Registration spam prevention |
| `/users/password` | POST | 3 | 1 hour | Password reset abuse prevention |
| `/auth/otp/send` | POST | 5 | 1 hour | OTP spam prevention |
| `/api/*` | ALL | 100 | 1 minute | General API abuse prevention |
| `/security` | GET | 20 | 1 minute | Security dashboard protection |

## 🛡️ Security Features

### Attack Pattern Detection
- **SQL Injection**: Blocks patterns like `1 OR 1=1`, `' OR '1'='1`
- **XSS Attacks**: Blocks `<script>` tags and JavaScript injection
- **Path Traversal**: Blocks `../` patterns and directory traversal
- **Command Injection**: Blocks shell command patterns

### User Agent Blocking
- Blocks requests with suspicious user agents:
  - `sqlmap/1.0`
  - `bot`, `crawler`, `spider`, `scraper`
  - Known attack tools

### IP-based Protection
- Rate limiting per IP address
- Blocklist support for malicious IPs
- Safelist for trusted IPs (localhost in development)

## 📊 Expected Test Results

### ✅ **Successful Rate Limiting**
```
Attempt 1: 401 (Unauthorized - expected)
Attempt 2: 401 (Unauthorized - expected)
Attempt 3: 401 (Unauthorized - expected)
Attempt 4: 401 (Unauthorized - expected)
Attempt 5: 401 (Unauthorized - expected)
Attempt 6: 429 (Too Many Requests) ← Rate limited!
```

### ✅ **Attack Pattern Blocking**
```
SQL Injection: 403 (Forbidden) ← Blocked!
XSS Attack: 403 (Forbidden) ← Blocked!
Path Traversal: 403 (Forbidden) ← Blocked!
```

### ✅ **Rate Limit Headers**
```
HTTP/1.1 429 Too Many Requests
Content-Type: application/json
Retry-After: 20
X-RateLimit-Limit: 5
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
```

## 🚀 Quick Start Testing

### 1. **Run Automated Tests**
```bash
cd /Users/phanindra/Documents/shopping_cart/services/user-service
bundle exec rspec spec/initializers/rack_attack_spec.rb
```

### 2. **Run Comprehensive Script**
```bash
ruby test_rate_limiting.rb
```

### 3. **Run Quick Shell Test**
```bash
./test_rate_limiting.sh
```

### 4. **Enable Attack Patterns in Development**
```bash
ENABLE_ATTACK_PATTERNS=true bundle exec rspec spec/initializers/rack_attack_spec.rb
```

## 🔍 Monitoring & Debugging

### Check Rate Limiting Status
```bash
# Rails console
rails console
> Rack::Attack.cache.store
> Rack::Attack.cache.read("rack::attack:login/ip:127.0.0.1")
```

### Monitor Logs
```bash
# Watch for rate limiting events
tail -f log/development.log | grep -i "rack::attack"

# Watch for security warnings
tail -f log/development.log | grep -i "security threat"
```

### Clear Rate Limit Cache
```bash
# Rails console
rails console
> Rack::Attack.cache.store.clear
```

## ⚠️ Troubleshooting

### Common Issues

1. **Rate limits not working**
   - Check if Rack::Attack is properly loaded
   - Verify cache store configuration
   - Check for conflicting middleware

2. **False positives**
   - Review rate limit thresholds
   - Check IP detection logic
   - Verify user agent patterns

3. **Performance issues**
   - Monitor cache store performance
   - Check for memory leaks
   - Optimize rate limit rules

### Environment-Specific Notes

- **Development**: Higher rate limits, attack patterns may be disabled
- **Test**: Use `ENABLE_ATTACK_PATTERNS=true` for full testing
- **Production**: All security features enabled, stricter limits

## 📈 Performance Considerations

- Rate limiting uses in-memory cache in development
- Production uses Redis for distributed rate limiting
- Monitor cache hit rates and memory usage
- Consider cache warming strategies for high-traffic scenarios

## 🔒 Security Best Practices

1. **Regular Testing**: Run tests before each deployment
2. **Monitor Metrics**: Track rate limiting events in production
3. **Review Logs**: Check for false positives and security threats
4. **Update Rules**: Adjust limits based on usage patterns
5. **Documentation**: Keep rate limit configurations documented

## 📚 Additional Resources

- [Rack::Attack Documentation](https://github.com/rack/rack-attack)
- [Rate Limiting Best Practices](https://cloud.google.com/architecture/rate-limiting-strategies-techniques)
- [OWASP Rate Limiting Guide](https://owasp.org/www-community/controls/Blocking_Brute_Force_Attacks)

---

**Last Updated**: January 2025  
**Test Status**: ✅ All tests passing  
**Security Status**: 🛡️ Protected
