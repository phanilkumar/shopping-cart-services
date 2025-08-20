# User Service

This is the user management microservice for the shopping cart application.

## Admin User Setup

An admin user has been created with the following credentials:

- **Email**: `admin@example.com`
- **Password**: `admin123`
- **Role**: Admin (role = 1)
- **Status**: Active (status = 1)

### Creating Admin User

To create the admin user in your database, run:

```bash
# Using the SQL script
docker compose exec postgres psql -U postgres -d user_service_dev -f /tmp/add_admin_user.sql

# Or using Rails console
docker compose exec user-service bin/rails runner "User.create!(email: 'admin@example.com', first_name: 'Admin', last_name: 'User', phone: '+919876543210', password: 'admin123', password_confirmation: 'admin123', role: 1, status: 1, email_verified_at: Time.current)"
```

## User Model Fixes

The User model has been updated to fix the following issues:

1. **INDIAN_STATES Constant Issue**: Moved the constant to the top of the class to fix reference errors
2. **Missing Methods**: Added required methods for authentication:
   - `full_name` - Returns user's full name
   - `update_last_login` - Updates last login timestamp
   - `generate_jwt_token` - Generates JWT authentication tokens
   - `generate_refresh_token` - Generates refresh tokens
   - `admin?` - Checks if user has admin role
   - `active?` - Checks if user is active

## API Endpoints

### Login
```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "admin123"
}
```

### Response
```json
{
  "status": "success",
  "message": "Login successful",
  "data": {
    "user": {
      "id": 2,
      "email": "admin@example.com",
      "first_name": "Admin",
      "last_name": "User",
      "full_name": "Admin User",
      "phone": "+919876543210",
      "status": 1,
      "role": 1,
      "last_login_at": "2025-08-20T11:18:26.341Z"
    },
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "91936dde50383298735acbf1dcf7d1edd213bdaac5147355e6afec3b4dd419d3"
  }
}
```

## Database Schema

The User model uses the following fields from the database:
- `id` - Primary key
- `email` - User email (unique)
- `first_name` - User's first name
- `last_name` - User's last name
- `phone` - User's phone number
- `status` - User status (1 = active)
- `role` - User role (1 = admin)
- `last_login_at` - Last login timestamp
- `email_verified_at` - Email verification timestamp
- `encrypted_password` - Devise encrypted password
- `created_at` / `updated_at` - Timestamps
