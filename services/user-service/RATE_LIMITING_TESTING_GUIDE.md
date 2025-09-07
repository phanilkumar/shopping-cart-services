# Rate Limiting & Brute Force Protection Testing Guide

## Overview

This guide provides comprehensive testing strategies for Rate Limiting & Brute Force Protection features implemented using Rack::Attack in the User Service.

## Current Rate Limiting Configuration

### 1. **Login Attempts**
- **Endpoint**: `/users/sign_in` (POST)
- **Limit**: 5 attempts per IP per 20 seconds
- **Purpose**: Prevent brute force attacks on login

### 2. **API Login Attempts**
- **Endpoint**: `/api/v1/auth/login` (POST)
- **Limit**: 5 attempts per IP per 20 seconds
- **Purpose**: Prevent brute force attacks on API authentication

### 3. **Registration Attempts**
- **Endpoint**: `/users` (POST)
- **Limit**: 3 attempts per IP per hour
- **Purpose**: Prevent spam registrations

### 4. **Password Reset Requests**
- **Endpoint**: `/users/password` (POST)
- **Limit**: 3 attempts per IP per hour
- **Purpose**: Prevent password reset abuse

### 5. **OTP Requests**
- **Endpoint**: `/auth/otp/send` (POST)
- **Limit**: 5 attempts per IP per hour
- **Purpose**: Prevent OTP spam

### 6. **General API Requests**
- **Endpoint**: `/api/*` (all methods)
- **Limit**: 100 requests per IP per minute
- **Purpose**: Prevent API abuse

### 7. **Security Dashboard**
- **Endpoint**: `/security` (GET)
- **Limit**: 20 requests per IP per minute
- **Purpose**: Prevent security dashboard abuse

## Testing Methods

### 1. **Automated Testing with RSpec**

#### Running the Test Suite
```bash
# Run all rate limiting tests
bundle exec rspec spec/initializers/rack_attack_spec.rb

# Run specific test groups
bundle exec rspec spec/initializers/rack_attack_spec.rb -e "rate limiting"
bundle exec rspec spec/initializers/rack_attack_spec.rb -e "security blocking"
```

#### Test Categories
- **Rate Limiting Tests**: Verify throttling works correctly
- **Security Blocking Tests**: Verify attack pattern detection
- **Response Header Tests**: Verify proper HTTP headers
- **Monitoring Tests**: Verify logging functionality

### 2. **Manual Testing with cURL**

#### Test Login Rate Limiting
```bash
# Test login rate limiting (should fail after 5 attempts)
for i in {1..7}; do
  echo "Attempt $i:"
  curl -X POST http://localhost:3000/users/sign_in \
    -H "Content-Type: application/json" \
    -d '{"user":{"email":"test@example.com","password":"wrong"}}' \
    -w "Status: %{http_code}\n" \
    -s
  echo "---"
  sleep 1
done
```

#### Test API Rate Limiting
```bash
# Test API rate limiting (should fail after 100 requests)
for i in {1..105}; do
  echo "Request $i:"
  curl -X GET http://localhost:3000/api/v1/users/1 \
    -w "Status: %{http_code}\n" \
    -s
  if [ $((i % 10)) -eq 0 ]; then
    echo "--- 10 requests completed ---"
  fi
done
```

#### Test Attack Pattern Blocking
```bash
# Test SQL injection blocking
curl -X GET "http://localhost:3000/api/v1/users?id=1 OR 1=1" \
  -w "Status: %{http_code}\n" \
  -s

# Test XSS blocking
curl -X GET "http://localhost:3000/api/v1/users?name=<script>alert(1)</script>" \
  -w "Status: %{http_code}\n" \
  -s

# Test path traversal blocking
curl -X GET "http://localhost:3000/api/v1/files?path=../../etc/passwd" \
  -w "Status: %{http_code}\n" \
  -s
```

### 3. **Load Testing with Apache Bench (ab)**

#### Test API Endpoint Load
```bash
# Test 200 requests to API endpoint
ab -n 200 -c 10 http://localhost:3000/api/v1/users/1

# Test with different concurrency levels
ab -n 1000 -c 50 http://localhost:3000/api/v1/users/1
```

#### Test Login Endpoint Load
```bash
# Test login endpoint with JSON payload
ab -n 20 -c 5 -p login_data.json -T application/json http://localhost:3000/users/sign_in
```

Create `login_data.json`:
```json
{"user":{"email":"test@example.com","password":"wrong"}}
```

### 4. **Browser Testing**

#### Using Browser Developer Tools
1. Open browser developer tools (F12)
2. Go to Network tab
3. Make multiple requests to test endpoints
4. Observe response codes and headers

#### Using Browser Extensions
- **Postman**: Create collections for rate limiting tests
- **REST Client**: VS Code extension for API testing
- **Thunder Client**: Lightweight API testing tool

### 5. **Monitoring and Logging Tests**

#### Check Application Logs
```bash
# Monitor Rails logs for rate limiting events
tail -f log/development.log | grep -i "rack::attack"

# Check for security warnings
tail -f log/development.log | grep -i "security threat"
```

#### Check Rate Limit Headers
```bash
# Test rate limit headers
curl -I http://localhost:3000/api/v1/users/1

# Expected headers:
# X-RateLimit-Limit: 100
# X-RateLimit-Remaining: 99
# X-RateLimit-Reset: [timestamp]
```

## Test Scenarios

### 1. **Basic Rate Limiting**
- **Objective**: Verify rate limits are enforced
- **Steps**:
  1. Make requests up to the limit
  2. Verify all requests succeed (or fail for wrong credentials)
  3. Make one additional request
  4. Verify 429 status code
  5. Check Retry-After header

### 2. **Rate Limit Reset**
- **Objective**: Verify rate limits reset after the period
- **Steps**:
  1. Trigger rate limiting
  2. Wait for the period to expire
  3. Make a new request
  4. Verify request succeeds

### 3. **Different IP Addresses**
- **Objective**: Verify rate limiting is per IP
- **Steps**:
  1. Test from one IP (trigger rate limit)
  2. Test from different IP
  3. Verify second IP is not rate limited

### 4. **Attack Pattern Detection**
- **Objective**: Verify malicious patterns are blocked
- **Steps**:
  1. Send requests with SQL injection patterns
  2. Send requests with XSS patterns
  3. Send requests with path traversal patterns
  4. Verify all return 403 status

### 5. **User Agent Blocking**
- **Objective**: Verify suspicious user agents are blocked
- **Steps**:
  1. Send requests with bot user agents
  2. Send requests with normal browser user agents
  3. Verify only bot requests are blocked

## Expected Responses

### Rate Limited Response (429)
```json
{
  "error": "Too many requests",
  "message": "Rate limit exceeded. Please try again later.",
  "retry_after": 20
}
```

**Headers:**
```
HTTP/1.1 429 Too Many Requests
Content-Type: application/json
Retry-After: 20
X-RateLimit-Limit: 5
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
```

### Blocked Response (403)
```json
{
  "error": "Forbidden",
  "message": "Request blocked due to security policy"
}
```

## Environment-Specific Testing

### Development Environment
- Rate limits are higher (e.g., 1000 requests vs 100)
- Attack pattern detection may be disabled
- More verbose logging

### Test Environment
- Use `ENABLE_ATTACK_PATTERNS=true` to enable security features
- Run full test suite
- Verify all rate limits work correctly

### Production Environment
- All security features enabled
- Stricter rate limits
- Monitor for false positives

## Troubleshooting

### Common Issues

1. **Rate limits not working**
   - Check cache store configuration
   - Verify Rack::Attack is properly loaded
   - Check for conflicting middleware

2. **False positives**
   - Review rate limit thresholds
   - Check IP detection logic
   - Verify user agent patterns

3. **Performance issues**
   - Monitor cache store performance
   - Check for memory leaks
   - Optimize rate limit rules

### Debug Commands

```bash
# Check Rack::Attack configuration
rails console
> Rack::Attack.cache.store
> Rack::Attack.throttles

# Clear rate limit cache
> Rack::Attack.cache.store.clear

# Check current rate limit status
> Rack::Attack.cache.read("rack::attack:login/ip:127.0.0.1")
```

## Best Practices

1. **Test in Multiple Environments**
   - Development, test, and production
   - Different rate limit configurations

2. **Monitor Performance**
   - Check response times
   - Monitor cache store usage
   - Watch for memory leaks

3. **Regular Testing**
   - Run automated tests in CI/CD
   - Perform manual testing before releases
   - Monitor production metrics

4. **Documentation**
   - Keep rate limit configurations documented
   - Update test cases when rules change
   - Maintain troubleshooting guides

## Security Considerations

1. **Rate Limit Bypass**
   - Test with different IP addresses
   - Test with different user agents
   - Test with different request patterns

2. **DoS Protection**
   - Verify rate limits prevent DoS attacks
   - Test with high concurrency
   - Monitor resource usage

3. **False Positives**
   - Test with legitimate high-volume usage
   - Verify normal users aren't blocked
   - Monitor production metrics

This comprehensive testing approach ensures that your Rate Limiting & Brute Force Protection features work correctly and provide the security you need.
