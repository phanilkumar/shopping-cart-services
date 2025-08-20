# 🔐 Admin Login Setup Guide

This guide explains how to set up and use admin login functionality for the microservices and admin dashboard.

## 📋 Current Status

### ✅ **What's Implemented:**
- Role-based user system (customer, admin, moderator)
- JWT authentication infrastructure
- Admin dashboard with authentication
- Admin user creation script

### 🔧 **What's New:**
- Admin login form for the dashboard
- Protected routes requiring admin authentication
- Admin user creation automation

## 🚀 **Quick Setup**

### Step 1: Start All Services
```bash
./start-all-services.sh
```

### Step 2: Create Admin User
```bash
ruby create-admin-user.rb
```

### Step 3: Access Admin Dashboard
1. Open http://localhost:3000
2. Login with:
   - **Email**: admin@example.com
   - **Password**: admin123456

## 📊 **Admin Dashboard Features**

Once logged in, you'll have access to:

- **Service Monitoring**: Real-time status of all microservices
- **Service Management**: Restart services with one click
- **Live Logs**: View logs from each service
- **System Analytics**: Performance metrics and statistics
- **User Management**: View and manage users (if implemented)

## 🔐 **Authentication Flow**

### **How Admin Login Works:**

1. **Login Request**: Admin enters credentials in the dashboard
2. **Auth Service**: Credentials are sent to auth-service (port 3001)
3. **Role Verification**: System checks if user has 'admin' role
4. **JWT Token**: If valid admin, JWT token is issued
5. **Dashboard Access**: Token is stored and dashboard becomes accessible

### **Security Features:**
- **Role-based Access**: Only users with 'admin' role can access dashboard
- **JWT Tokens**: Secure token-based authentication
- **Token Storage**: Tokens stored in localStorage
- **Auto-logout**: Tokens expire after 1 hour

## 👤 **Admin User Management**

### **Default Admin Credentials:**
- **Email**: admin@example.com
- **Password**: admin123456

### **Creating Additional Admin Users:**

#### **Option 1: Using the Script**
```bash
# Edit the script to change credentials
nano create-admin-user.rb

# Run the script
ruby create-admin-user.rb
```

#### **Option 2: Manual Creation**
```bash
# Register a new user via API
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "newadmin@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "first_name": "New",
      "last_name": "Admin",
      "phone": "+1234567890"
    }
  }'

# Update user role to admin (replace USER_ID with actual ID)
curl -X PUT http://localhost:3001/api/v1/users/USER_ID \
  -H "Content-Type: application/json" \
  -d '{"user": {"role": "admin"}}'
```

## 🛠️ **Customization**

### **Changing Admin Credentials:**
1. Edit `create-admin-user.rb`
2. Modify the `admin_data` hash
3. Re-run the script

### **Adding More Admin Features:**
1. Extend the admin dashboard components
2. Add new protected routes
3. Implement additional admin-only functionality

### **Customizing Authentication:**
1. Modify `LoginForm.tsx` for custom styling
2. Update `AdminAuthContext.tsx` for additional logic
3. Extend `ProtectedRoute.tsx` for more complex authorization

## 🔍 **Troubleshooting**

### **Admin Login Issues:**

#### **"Access denied. Admin privileges required."**
- User exists but doesn't have admin role
- Solution: Update user role to 'admin'

#### **"Login failed"**
- Check if auth-service is running on port 3001
- Verify admin user exists in the database
- Check network connectivity

#### **Dashboard not loading after login**
- Check browser console for errors
- Verify JWT token is valid
- Clear localStorage and try again

### **Service Issues:**

#### **Admin user creation fails**
```bash
# Check if services are running
./check-services-status.sh

# Restart services if needed
./start-all-services.sh
```

#### **Database issues**
```bash
# Check service logs
tail -f services/auth-service/log/development.log
```

## 📝 **API Endpoints**

### **Admin Authentication Endpoints:**

#### **Login**
```http
POST http://localhost:3001/api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "admin123456"
}
```

#### **Register**
```http
POST http://localhost:3001/api/v1/auth/register
Content-Type: application/json

{
  "user": {
    "email": "admin@example.com",
    "password": "admin123456",
    "password_confirmation": "admin123456",
    "first_name": "Admin",
    "last_name": "User",
    "phone": "+1234567890"
  }
}
```

#### **Update User Role**
```http
PUT http://localhost:3001/api/v1/users/{user_id}
Content-Type: application/json

{
  "user": {
    "role": "admin"
  }
}
```

## 🔒 **Security Best Practices**

### **Production Considerations:**
1. **Change default credentials** immediately
2. **Use strong passwords** for admin accounts
3. **Enable HTTPS** for all communications
4. **Implement rate limiting** on login endpoints
5. **Add two-factor authentication** for admin accounts
6. **Regular security audits** of admin access

### **Environment Variables:**
```bash
# Set secure JWT secret
export JWT_SECRET_KEY="your-secure-secret-key"

# Set admin email domain restrictions
export ADMIN_EMAIL_DOMAIN="yourcompany.com"
```

## 📚 **Additional Resources**

- **JWT Documentation**: https://jwt.io/
- **Rails Devise**: https://github.com/heartcombo/devise
- **React Authentication**: https://reactjs.org/docs/context.html
- **Microservices Security**: https://microservices.io/patterns/security/

## 🆘 **Getting Help**

If you encounter issues:
1. Check the service logs in `services/*/log/`
2. Verify all services are running with `./check-services-status.sh`
3. Ensure admin user exists and has correct role
4. Check browser console for JavaScript errors
5. Verify network connectivity between services
