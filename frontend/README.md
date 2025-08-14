# Frontend - Microservices Integration

This frontend has been updated to work with the two microservices architecture:

## 🏗️ **Architecture Overview**

### **Services:**
- **Auth Service** (Port 3000): Handles traditional email/password authentication
- **OAuth Service** (Port 3001): Handles third-party OAuth authentication

### **Frontend Integration:**
- **React + TypeScript**: Modern frontend with type safety
- **Redux Toolkit**: State management for authentication
- **Material-UI**: Modern UI components
- **Axios**: HTTP client for API communication

## 🔧 **Key Changes Made**

### **1. API Service Layer**
- **`src/services/api/authAPI.ts`**: Auth Service client
- **`src/services/api/oauthAPI.ts`**: OAuth Service client  
- **`src/services/api/index.ts`**: Unified API service

### **2. State Management**
- **`src/store/slices/authSlice.ts`**: Updated for dual-service support
- **`src/contexts/AuthContext.tsx`**: New authentication context

### **3. Components**
- **`src/components/auth/OAuthButtons.tsx`**: OAuth provider buttons
- **`src/components/MicroservicesStatus.tsx`**: Service health monitoring

## 🚀 **Getting Started**

### **Prerequisites:**
1. Ensure both microservices are running:
   ```bash
   # Auth Service (Port 3000)
   cd services/auth-service
   rails server -p 3000
   
   # OAuth Service (Port 3001)
   cd services/oauth-service
   rails server -p 3001
   ```

2. Install frontend dependencies:
   ```bash
   cd frontend
   npm install
   ```

3. Start the frontend:
   ```bash
   npm start
   ```

## 🔐 **Authentication Flow**

### **Traditional Auth (Auth Service):**
1. User enters email/password
2. Frontend calls Auth Service API
3. Service validates credentials
4. Returns JWT token
5. Frontend stores token and user data

### **OAuth Auth (OAuth Service):**
1. User clicks OAuth provider button
2. Frontend redirects to OAuth Service
3. Service handles OAuth flow
4. Returns user data and token
5. Frontend stores OAuth token and user data

## 📁 **File Structure**

```
src/
├── services/
│   └── api/
│       ├── authAPI.ts          # Auth Service client
│       ├── oauthAPI.ts         # OAuth Service client
│       └── index.ts            # Unified API service
├── store/
│   └── slices/
│       └── authSlice.ts        # Updated auth state management
├── contexts/
│   └── AuthContext.tsx         # Authentication context
├── components/
│   ├── auth/
│   │   └── OAuthButtons.tsx    # OAuth provider buttons
│   └── MicroservicesStatus.tsx # Service health monitoring
└── App.tsx                     # Main app with microservices status
```

## 🔧 **Configuration**

### **Environment Variables:**
```bash
# Auth Service URL (default: http://localhost:3000/api/v1)
REACT_APP_AUTH_SERVICE_URL=http://localhost:3000/api/v1

# OAuth Service URL (default: http://localhost:3001/api/v1)
REACT_APP_OAUTH_SERVICE_URL=http://localhost:3001/api/v1
```

## 🧪 **Testing**

### **Health Check:**
The frontend includes a `MicroservicesStatus` component that:
- Displays real-time status of both services
- Shows service versions and ports
- Allows manual refresh of health checks

### **API Testing:**
```bash
# Test Auth Service
curl http://localhost:3000/health

# Test OAuth Service  
curl http://localhost:3001/health
```

## 🔄 **Token Management**

### **Auth Service Tokens:**
- Stored in `localStorage` as `authToken` and `authRefreshToken`
- Automatic token refresh on 401 errors
- Automatic logout on refresh failure

### **OAuth Service Tokens:**
- Stored in `localStorage` as `oauthToken` and `oauthRefreshToken`
- Separate token management for OAuth users
- Automatic cleanup on logout

## 🎯 **Features**

### **✅ Implemented:**
- [x] Dual-service authentication
- [x] OAuth provider integration
- [x] Service health monitoring
- [x] Automatic token refresh
- [x] Unified user management
- [x] Type-safe API calls
- [x] Error handling and notifications

### **🔄 In Progress:**
- [ ] Real OAuth provider configuration
- [ ] Advanced user profile management
- [ ] Service discovery and load balancing

## 🐛 **Troubleshooting**

### **Common Issues:**

1. **Services Not Responding:**
   ```bash
   # Check if services are running
   lsof -i :3000 -i :3001
   
   # Restart services if needed
   pkill -f "rails server"
   ```

2. **CORS Issues:**
   - Ensure both services have CORS configured
   - Check browser console for CORS errors

3. **Token Issues:**
   - Clear localStorage: `localStorage.clear()`
   - Check token expiration
   - Verify service endpoints

## 📝 **API Endpoints**

### **Auth Service (Port 3000):**
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/refresh` - Token refresh
- `DELETE /api/v1/auth/logout` - User logout
- `GET /api/v1/users/:id` - Get user profile
- `PUT /api/v1/users/:id` - Update user profile
- `GET /health` - Health check

### **OAuth Service (Port 3001):**
- `GET /api/v1/oauth/:provider` - OAuth provider redirect
- `GET /api/v1/oauth/callback` - OAuth callback
- `GET /api/v1/users/:id` - Get OAuth user profile
- `PUT /api/v1/users/:id` - Update OAuth user profile
- `GET /health` - Health check

## 🎉 **Success!**

Your frontend is now fully integrated with the microservices architecture! 

**Next Steps:**
1. Start both microservices
2. Start the frontend
3. Test authentication flows
4. Monitor service health
5. Configure real OAuth providers

---

**Happy coding! 🚀**
