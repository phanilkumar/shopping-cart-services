# 🧪 Complete Testing Guide for Microservices

## 📋 Overview

This document provides a comprehensive guide to testing both **Auth Service** and **OAuth Service** microservices. We've created multiple testing approaches to ensure thorough validation of all functionality.

## 🚀 Quick Start Testing

### 1. **Quick Test** (Fastest - 30 seconds)
```bash
./quick_test.sh
```
- Tests basic health endpoints
- Verifies services can start and respond
- Perfect for CI/CD pipelines

### 2. **Individual Service Tests** (Medium - 2-3 minutes each)
```bash
# Test Auth Service only
./auth-service/test_api.sh

# Test OAuth Service only  
./oauth-service/test_api.sh
```
- Comprehensive testing of each service
- Tests all endpoints and error cases
- Includes authentication flows

### 3. **Full Integration Test** (Complete - 5-7 minutes)
```bash
./test_all_services.sh
```
- Tests both services together
- Includes integration scenarios
- Cross-service communication testing

## 📊 Test Coverage

### 🔐 Auth Service Tests

| Test Category | Endpoints | Test Cases |
|---------------|-----------|------------|
| **Health Check** | `GET /health` | Service status |
| **Authentication** | `POST /auth/login`<br>`POST /auth/register`<br>`POST /auth/refresh`<br>`DELETE /auth/logout` | Login, registration, token refresh, logout |
| **User Management** | `GET /users/:id`<br>`PUT /users/:id`<br>`GET /users/:id/profile` | Profile viewing, updating |
| **Password Management** | `POST /password/forgot`<br>`POST /password/reset`<br>`PUT /password/change` | Password reset flow |
| **Error Handling** | All endpoints | Invalid data, unauthorized access |

### 🔗 OAuth Service Tests

| Test Category | Endpoints | Test Cases |
|---------------|-----------|------------|
| **Health Check** | `GET /health` | Service status |
| **OAuth Providers** | `GET /oauth/google`<br>`GET /oauth/facebook`<br>`GET /oauth/github`<br>`GET /oauth/twitter`<br>`GET /oauth/linkedin` | Provider redirects |
| **OAuth Callbacks** | `GET /oauth/callback` | Callback handling |
| **User Management** | `GET /users/:id`<br>`PUT /users/:id`<br>`GET /users/:id/profile` | Profile with OAuth accounts |
| **Integration** | Multiple providers | Cross-provider authentication |

## 🛠️ Testing Tools

### 1. **Automated Scripts**
- **`quick_test.sh`** - Fast health checks
- **`test_api.sh`** - Individual service testing
- **`test_all_services.sh`** - Complete integration testing

### 2. **Manual Testing**
- **curl commands** - Direct API testing
- **Postman collection** - GUI-based testing
- **Browser testing** - OAuth flow testing

### 3. **Development Tools**
- **Rails console** - Model and service testing
- **RSpec** - Unit and integration tests
- **Database testing** - Data validation

## 📝 Manual Testing Commands

### Auth Service Manual Tests

```bash
# Health check
curl http://localhost:3000/health

# Register user
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123","password_confirmation":"password123","first_name":"John","last_name":"Doe","phone":"+1234567890"}}'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get profile (with token)
curl -X GET http://localhost:3000/api/v1/users/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### OAuth Service Manual Tests

```bash
# Health check
curl http://localhost:3001/health

# OAuth redirects
curl http://localhost:3001/api/v1/oauth/google
curl http://localhost:3001/api/v1/oauth/facebook

# OAuth callback
curl http://localhost:3001/api/v1/oauth/callback?provider=google

# Get profile with OAuth accounts
curl -X GET http://localhost:3001/api/v1/users/1/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔧 Testing Configuration

### Environment Setup
```bash
# Set JWT secret for testing
export JWT_SECRET_KEY="test-secret-key-123"

# Set database URLs
export DATABASE_URL="postgresql://localhost/auth_service_development"
export OAUTH_DATABASE_URL="postgresql://localhost/oauth_service_development"
```

### Database Setup
```bash
# Auth Service
cd auth-service
rails db:create db:migrate

# OAuth Service
cd oauth-service
rails db:create db:migrate
```

## 📈 Performance Testing

### Load Testing
```bash
# Test health endpoint performance
ab -n 1000 -c 10 http://localhost:3000/health

# Test login endpoint performance
ab -n 100 -c 5 -p login_data.json -T application/json http://localhost:3000/api/v1/auth/login
```

### Memory Testing
```bash
# Monitor Rails processes
ps aux | grep rails

# Check memory usage
top -p $(pgrep -f "rails server")
```

## 🐛 Debugging

### Common Issues

1. **Port Conflicts**
   ```bash
   # Kill existing servers
   pkill -f "rails server"
   ```

2. **Database Issues**
   ```bash
   # Reset databases
   rails db:drop db:create db:migrate
   ```

3. **JWT Token Issues**
   ```bash
   # Check JWT secret
   echo $JWT_SECRET_KEY
   ```

### Debug Mode
```bash
# Start with debug logging
RAILS_ENV=development rails server -p 3000

# Check logs
tail -f log/development.log
```

## ✅ Test Checklist

### Pre-Testing Setup
- [ ] PostgreSQL running
- [ ] Ports 3000 and 3001 available
- [ ] JWT_SECRET_KEY set
- [ ] Databases created and migrated

### Auth Service Tests
- [ ] Health endpoint responds
- [ ] User registration works
- [ ] User login works
- [ ] JWT tokens generated
- [ ] Protected routes require auth
- [ ] Password reset flow works
- [ ] Token refresh works
- [ ] Logout works
- [ ] Error handling works

### OAuth Service Tests
- [ ] Health endpoint responds
- [ ] OAuth redirects work
- [ ] OAuth callbacks work
- [ ] User creation from OAuth
- [ ] OAuth account linking
- [ ] Multiple providers work
- [ ] Profile shows OAuth accounts

### Integration Tests
- [ ] Both services run simultaneously
- [ ] Cross-service communication
- [ ] No port conflicts
- [ ] Shared JWT validation

## 🎯 Expected Results

### Successful Test Run
```
╔══════════════════════════════════════════════════════════════╗
║                        TEST SUMMARY                          ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  ✅ Total Tests Passed: 25                                  ║
║  ❌ Total Tests Failed: 0                                   ║
║  📊 Total Tests: 25                                         ║
║                                                              ║
║  🎉 ALL TESTS PASSED! 🎉                                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

## 🚀 Next Steps

1. **Configure Real OAuth Providers**
   - Set up Google OAuth credentials
   - Configure Facebook app
   - Add GitHub OAuth app

2. **Production Testing**
   - Set up staging environment
   - Configure production databases
   - Test with real OAuth providers

3. **Advanced Testing**
   - Add unit tests with RSpec
   - Implement integration tests
   - Set up CI/CD pipeline

4. **Monitoring**
   - Add application monitoring
   - Set up error tracking
   - Implement performance monitoring

## 📞 Support

If you encounter issues:

1. **Check the logs**: `tail -f log/development.log`
2. **Verify database**: `rails db:status`
3. **Test connectivity**: `curl http://localhost:3000/health`
4. **Check processes**: `ps aux | grep rails`

## 🎉 Success Criteria

Your microservices are working correctly when:

- ✅ All test scripts pass
- ✅ Both services start without errors
- ✅ Health endpoints return 200
- ✅ User registration and login work
- ✅ OAuth flows complete successfully
- ✅ JWT tokens are generated and validated
- ✅ Protected routes require authentication
- ✅ Error handling works properly
- ✅ Both services can run simultaneously

**Congratulations! Your microservices are ready for production! 🚀**
