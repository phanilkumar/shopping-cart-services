# User Service Integration Guide

This document outlines the complete integration of the user-service microservice into the frontend application.

## 🏗️ Architecture Overview

The user-service integration follows a clean architecture pattern with the following layers:

```
Frontend (React + TypeScript)
├── Components (UI Layer)
│   ├── auth/
│   │   ├── LoginForm.tsx
│   │   └── RegisterForm.tsx
│   └── user/
│       └── UserProfile.tsx
├── Pages (Route Layer)
│   ├── AuthPage.tsx
│   └── DashboardPage.tsx
├── Contexts (State Management)
│   └── UserContext.tsx
├── Services (API Layer)
│   └── api/
│       ├── userAPI.ts
│       └── index.ts
└── Types (Type Definitions)
    └── userAPI.ts (interfaces)
```

## 🔧 Configuration

### Environment Variables

The frontend uses the following environment variables for user-service configuration:

```env
VITE_USER_SERVICE_URL=http://localhost:3001/api/v1
```

### Vite Proxy Configuration

The `vite.config.ts` includes proxy configuration for the user-service:

```typescript
server: {
  proxy: {
    '/api/v1': {
      target: 'http://localhost:3001',
      changeOrigin: true,
      secure: false,
    },
  },
}
```

## 📡 API Integration

### User Service API (`userAPI.ts`)

The `userAPI.ts` file provides a complete interface to the user-service with the following features:

#### Authentication Methods
- `login(credentials)` - User login
- `register(userData)` - User registration
- `logout()` - User logout
- `refreshToken(refreshToken)` - Token refresh

#### User Management
- `getCurrentUser()` - Get current user profile
- `getUserById(userId)` - Get user by ID
- `updateProfile(userData)` - Update user profile
- `changePassword(currentPassword, newPassword, confirmPassword)` - Change password

#### Admin Functions
- `getAllUsers(page, perPage)` - Get all users (admin only)
- `createUser(userData)` - Create new user (admin only)
- `updateUser(userId, userData)` - Update user (admin only)
- `deleteUser(userId)` - Delete user (admin only)
- `activateUser(userId)` - Activate user (admin only)
- `deactivateUser(userId)` - Deactivate user (admin only)
- `suspendUser(userId, reason)` - Suspend user (admin only)

#### Password Management
- `forgotPassword(email)` - Request password reset
- `resetPassword(token, password, passwordConfirmation)` - Reset password

#### Utility Functions
- `isAuthenticated()` - Check if user is authenticated
- `getStoredUser()` - Get user from localStorage
- `setStoredUser(user)` - Store user in localStorage
- `clearStoredUser()` - Clear user from localStorage
- `healthCheck()` - Service health check

### Type Definitions

```typescript
interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone: string;
  status: 'active' | 'inactive' | 'pending' | 'suspended';
  role: 'user' | 'admin' | 'moderator';
  last_login_at: string | null;
  created_at: string;
  updated_at: string;
}

interface LoginCredentials {
  email: string;
  password: string;
}

interface CreateUserData {
  email: string;
  password: string;
  password_confirmation: string;
  first_name: string;
  last_name: string;
  phone: string;
}

interface UpdateUserData {
  first_name?: string;
  last_name?: string;
  phone?: string;
  email?: string;
}
```

## 🎯 State Management

### User Context (`UserContext.tsx`)

The UserContext provides centralized state management for user authentication and profile data:

#### State Structure
```typescript
interface UserState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}
```

#### Available Actions
- `login(credentials)` - Authenticate user
- `register(userData)` - Register new user
- `logout()` - Logout user
- `updateProfile(userData)` - Update user profile
- `changePassword(currentPassword, newPassword, confirmPassword)` - Change password
- `forgotPassword(email)` - Request password reset
- `resetPassword(token, password, passwordConfirmation)` - Reset password
- `clearError()` - Clear error state
- `refreshUser()` - Refresh user data

#### Usage Example
```typescript
import { useUser } from '../contexts/UserContext';

const MyComponent = () => {
  const { state, login, logout } = useUser();
  
  const handleLogin = async () => {
    try {
      await login({ email: 'user@example.com', password: 'password' });
    } catch (error) {
      console.error('Login failed:', error);
    }
  };
  
  return (
    <div>
      {state.isAuthenticated ? (
        <button onClick={logout}>Logout</button>
      ) : (
        <button onClick={handleLogin}>Login</button>
      )}
    </div>
  );
};
```

## 🎨 UI Components

### Authentication Components

#### LoginForm
- Email and password validation
- Error handling and display
- Loading states
- Integration with UserContext

#### RegisterForm
- Complete user registration form
- Field validation (email, phone, password)
- Password confirmation
- Indian phone number validation

### User Management Components

#### UserProfile
- Display user information
- Edit profile functionality
- Status and role indicators
- Logout functionality

### Page Components

#### AuthPage
- Tabbed interface for login/register
- Seamless switching between forms
- Success handling and redirection

#### DashboardPage
- User dashboard with navigation cards
- Account information display
- Quick actions
- User stats and metadata

## 🔐 Security Features

### Token Management
- Automatic token storage in localStorage
- Token refresh on 401 responses
- Automatic logout on token expiration
- Secure token handling

### Input Validation
- Client-side form validation
- Email format validation
- Password strength requirements
- Phone number format validation (Indian format)

### Error Handling
- Comprehensive error messages
- User-friendly error display
- Graceful error recovery
- Network error handling

## 🚀 Getting Started

### 1. Start the User Service
```bash
cd shopping_cart
docker compose up user-service
```

### 2. Start the Frontend
```bash
cd frontend
npm run dev
```

### 3. Access the Application
- Frontend: http://localhost:3005
- User Service: http://localhost:3001

### 4. Test Authentication
1. Navigate to http://localhost:3005
2. Click "Sign Up" to create a new account
3. Or use existing credentials to login
4. Access the dashboard and profile features

## 🧪 Testing

### Manual Testing Checklist

#### Authentication Flow
- [ ] User registration with valid data
- [ ] User registration with invalid data (validation)
- [ ] User login with valid credentials
- [ ] User login with invalid credentials
- [ ] Logout functionality
- [ ] Token refresh on 401

#### Profile Management
- [ ] View user profile
- [ ] Edit profile information
- [ ] Save profile changes
- [ ] Cancel profile edits
- [ ] Form validation

#### Error Handling
- [ ] Network errors
- [ ] Validation errors
- [ ] Server errors
- [ ] Token expiration

### API Testing

Test the user-service endpoints directly:

```bash
# Health check
curl http://localhost:3001/api/v1/health

# User registration
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "9876543210"
    }
  }'

# User login
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## 🔧 Troubleshooting

### Common Issues

#### 1. CORS Errors
**Problem**: Cross-origin requests blocked
**Solution**: Ensure user-service CORS is configured for localhost:3005

#### 2. Proxy Issues
**Problem**: API calls not reaching user-service
**Solution**: Check vite.config.ts proxy configuration

#### 3. Token Issues
**Problem**: Authentication tokens not working
**Solution**: Verify JWT_SECRET_KEY is consistent across services

#### 4. Database Connection
**Problem**: User-service can't connect to database
**Solution**: Ensure PostgreSQL is running and accessible

### Debug Mode

Enable debug logging in the browser console:

```typescript
// In userAPI.ts
const userAPI = axios.create({
  baseURL: USER_SERVICE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add request/response logging
userAPI.interceptors.request.use(request => {
  console.log('Request:', request);
  return request;
});

userAPI.interceptors.response.use(
  response => {
    console.log('Response:', response);
    return response;
  },
  error => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);
```

## 📚 API Reference

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | User login |
| POST | `/api/v1/auth/register` | User registration |
| DELETE | `/api/v1/auth/logout` | User logout |
| POST | `/api/v1/auth/refresh` | Refresh token |

### User Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/users/me` | Get current user |
| PUT | `/api/v1/users/me` | Update current user |
| PUT | `/api/v1/users/me/password` | Change password |

### Admin Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/users` | Get all users |
| POST | `/api/v1/admin/users` | Create user |
| PUT | `/api/v1/admin/users/:id` | Update user |
| DELETE | `/api/v1/admin/users/:id` | Delete user |
| PATCH | `/api/v1/admin/users/:id/activate` | Activate user |
| PATCH | `/api/v1/admin/users/:id/deactivate` | Deactivate user |
| PATCH | `/api/v1/admin/users/:id/suspend` | Suspend user |

### Password Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/password/forgot` | Request password reset |
| POST | `/api/v1/password/reset` | Reset password |

### Health Check

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/health` | Service health check |

## 🔄 Future Enhancements

### Planned Features
- [ ] OAuth integration (Google, Facebook, GitHub)
- [ ] Two-factor authentication
- [ ] Email verification
- [ ] Phone number verification
- [ ] User preferences
- [ ] Activity logging
- [ ] User analytics

### Performance Optimizations
- [ ] Request caching
- [ ] Lazy loading
- [ ] Code splitting
- [ ] Service worker for offline support

### Security Enhancements
- [ ] Rate limiting
- [ ] CSRF protection
- [ ] XSS prevention
- [ ] Input sanitization

## 📞 Support

For issues related to user-service integration:

1. Check the troubleshooting section
2. Review the API documentation
3. Test with curl commands
4. Check browser developer tools
5. Verify service logs

## 📄 License

This integration is part of the shopping cart microservices project.
