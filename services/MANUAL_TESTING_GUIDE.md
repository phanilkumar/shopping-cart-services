# 🧪 Manual Testing Guide for Microservices

This guide provides step-by-step instructions for manually testing both Auth Service and OAuth Service.

## 📋 Prerequisites

- **curl** installed
- **Rails** installed
- **PostgreSQL** running
- **Ports 3000 and 3001** available

## 🚀 Quick Start

### 1. Start Both Services

```bash
# Terminal 1 - Auth Service
cd auth-service
rails server -p 3000

# Terminal 2 - OAuth Service  
cd oauth-service
rails server -p 3001
```

### 2. Run Automated Tests

```bash
# Make scripts executable
chmod +x test_all_services.sh
chmod +x auth-service/test_api.sh
chmod +x oauth-service/test_api.sh

# Run all tests
./test_all_services.sh
```

## 🔐 Auth Service Testing

### Health Check
```bash
curl http://localhost:3000/health
```

### User Registration
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+1234567890"
    }
  }'
```

### User Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Get User Profile (with token)
```bash
# Replace YOUR_TOKEN with the token from login response
curl -X GET http://localhost:3000/api/v1/users/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Update User Profile
```bash
curl -X PUT http://localhost:3000/api/v1/users/1 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "first_name": "Jane",
      "last_name": "Smith"
    }
  }'
```

### Password Reset
```bash
# Request password reset
curl -X POST http://localhost:3000/api/v1/password/forgot \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com"
  }'

# Reset password (with token)
curl -X POST http://localhost:3000/api/v1/password/reset \
  -H "Content-Type: application/json" \
  -d '{
    "token": "reset_token_here",
    "password": "newpassword123",
    "password_confirmation": "newpassword123"
  }'
```

### Token Refresh
```bash
curl -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "your_refresh_token_here"
  }'
```

### Logout
```bash
curl -X DELETE http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔗 OAuth Service Testing

### Health Check
```bash
curl http://localhost:3001/health
```

### OAuth Provider Redirects
```bash
# Google OAuth
curl http://localhost:3001/api/v1/oauth/google

# Facebook OAuth
curl http://localhost:3001/api/v1/oauth/facebook

# GitHub OAuth
curl http://localhost:3001/api/v1/oauth/github

# Twitter OAuth
curl http://localhost:3001/api/v1/oauth/twitter

# LinkedIn OAuth
curl http://localhost:3001/api/v1/oauth/linkedin
```

### OAuth Callback (Mock)
```bash
# Google callback
curl http://localhost:3001/api/v1/oauth/callback?provider=google

# Facebook callback
curl http://localhost:3001/api/v1/oauth/callback?provider=facebook

# GitHub callback
curl http://localhost:3001/api/v1/oauth/callback?provider=github
```

### Get User Profile with OAuth Accounts
```bash
# Replace YOUR_TOKEN with the token from OAuth callback
curl -X GET http://localhost:3001/api/v1/users/1/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🧪 Error Testing

### Invalid Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "wrong@example.com",
    "password": "wrongpassword"
  }'
```

### Invalid Registration
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "invalid-email",
      "password": "short",
      "password_confirmation": "short"
    }
  }'
```

### Unauthorized Access
```bash
curl -X GET http://localhost:3000/api/v1/users/1
```

## 🔧 Using Postman

### Import Collection
1. Open Postman
2. Import the following collection structure:

```json
{
  "info": {
    "name": "Microservices Testing",
    "description": "Test collection for Auth and OAuth services"
  },
  "item": [
    {
      "name": "Auth Service",
      "item": [
        {
          "name": "Health Check",
          "request": {
            "method": "GET",
            "url": "http://localhost:3000/health"
          }
        },
        {
          "name": "Register User",
          "request": {
            "method": "POST",
            "url": "http://localhost:3000/api/v1/auth/register",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"user\": {\n    \"email\": \"test@example.com\",\n    \"password\": \"password123\",\n    \"password_confirmation\": \"password123\",\n    \"first_name\": \"John\",\n    \"last_name\": \"Doe\",\n    \"phone\": \"+1234567890\"\n  }\n}"
            }
          }
        }
      ]
    },
    {
      "name": "OAuth Service",
      "item": [
        {
          "name": "Health Check",
          "request": {
            "method": "GET",
            "url": "http://localhost:3001/health"
          }
        },
        {
          "name": "Google OAuth",
          "request": {
            "method": "GET",
            "url": "http://localhost:3001/api/v1/oauth/google"
          }
        }
      ]
    }
  ]
}
```

## 📊 Expected Responses

### Successful Registration
```json
{
  "status": "success",
  "message": "Registration successful",
  "data": {
    "user": {
      "id": 1,
      "email": "test@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "full_name": "John Doe",
      "phone": "+1234567890",
      "status": "active",
      "role": "customer"
    },
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9..."
  }
}
```

### Successful Login
```json
{
  "status": "success",
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "email": "test@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "full_name": "John Doe"
    },
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9..."
  }
}
```

### OAuth Callback Response
```json
{
  "status": "success",
  "message": "Google authentication successful",
  "data": {
    "user": {
      "id": 1,
      "email": "user_abc123@example.com",
      "first_name": "User",
      "last_name": "Name",
      "connected_providers": ["google"]
    },
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
    "provider": "google"
  }
}
```

## 🐛 Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Kill existing Rails servers
   pkill -f "rails server"
   ```

2. **Database connection issues**
   ```bash
   # Reset database
   rails db:drop db:create db:migrate
   ```

3. **JWT token issues**
   ```bash
   # Check JWT secret in environment
   echo $JWT_SECRET_KEY
   ```

4. **CORS issues**
   ```bash
   # Check CORS configuration in config/initializers/cors.rb
   ```

### Debug Mode

Start services in debug mode:
```bash
# Auth Service with debug
cd auth-service
RAILS_ENV=development rails server -p 3000

# OAuth Service with debug
cd oauth-service
RAILS_ENV=development rails server -p 3001
```

## 📈 Performance Testing

### Load Testing with Apache Bench
```bash
# Test health endpoint
ab -n 100 -c 10 http://localhost:3000/health

# Test login endpoint
ab -n 50 -c 5 -p login_data.json -T application/json http://localhost:3000/api/v1/auth/login
```

### Memory Usage
```bash
# Monitor Rails process
ps aux | grep rails
```

## ✅ Test Checklist

- [ ] Health endpoints respond
- [ ] User registration works
- [ ] User login works
- [ ] JWT tokens are generated
- [ ] Protected routes require authentication
- [ ] Password reset flow works
- [ ] OAuth redirects work
- [ ] OAuth callbacks work
- [ ] User profile updates work
- [ ] Error handling works
- [ ] Both services can run simultaneously
- [ ] Cross-service communication works

## 🎯 Next Steps

1. **Configure real OAuth providers** (Google, Facebook, etc.)
2. **Set up environment variables** for production
3. **Add rate limiting** and security measures
4. **Implement real email sending** for password reset
5. **Add comprehensive logging** and monitoring
6. **Set up CI/CD pipeline** for automated testing
