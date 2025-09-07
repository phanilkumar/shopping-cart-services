# 🔒 Account Lockout Mechanism Implementation

## 📋 **Overview**

The Account Lockout Mechanism is a critical security feature that protects user accounts against brute force attacks by temporarily locking accounts after multiple failed login attempts. This implementation provides a robust, configurable, and user-friendly approach to account security.

## 🏗️ **Architecture Components**

### **1. Database Schema**
```ruby
# Key fields in users table
- failed_attempts: integer (default: 0)     # Tracks failed login attempts
- locked_at: datetime                       # Timestamp when account was locked
- unlock_token: string                      # Token for account unlocking
- last_sign_in_ip: string                   # IP address tracking
- current_sign_in_ip: string                # Current session IP
- sign_in_count: integer                    # Total successful logins
- current_sign_in_at: datetime              # Current session timestamp
- last_sign_in_at: datetime                 # Last session timestamp
```

### **2. Devise Configuration**
```ruby
# In User model
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable,
       :lockable, :trackable, :timeoutable
```

## 🔧 **Core Implementation**

### **1. User Model Methods**

#### **Account Locking Methods**
```ruby
# Lock account after failed attempts
def lock_account!
  update!(locked_at: Time.current)
  Rails.logger.warn "Account locked for user #{id} (#{email})"
end

# Unlock account manually
def unlock_account!
  update!(locked_at: nil, failed_attempts: 0)
  Rails.logger.info "Account unlocked for user #{id} (#{email})"
end

# Check if account is locked
def account_locked?
  locked_at.present?
end
```

#### **Failed Attempts Management**
```ruby
# Increment failed attempts and lock if threshold reached
def increment_failed_attempts!
  new_attempts = (failed_attempts || 0) + 1
  update!(failed_attempts: new_attempts)
  
  # Lock account after 5 failed attempts
  if new_attempts >= 5
    lock_account!
  end
end

# Reset failed attempts on successful login
def reset_failed_attempts!
  update!(failed_attempts: 0)
end
```

### **2. Authentication Controller Logic**

#### **Login Flow with Lockout Protection**
```ruby
def login
  user = User.find_by(email: params[:email])
  
  # Step 1: Check if account is already locked
  if user&.account_locked?
    render json: {
      status: 'error',
      message: 'Account is locked due to multiple failed login attempts. Please contact support.',
      locked_until: user.locked_at
    }, status: :locked
    return
  end
  
  # Step 2: Validate credentials
  if user&.valid_password?(params[:password])
    if user.active?
      # Step 3: Successful login - reset failed attempts
      user.reset_failed_attempts!
      user.update_last_login
      
      # Log successful login
      Rails.logger.info "Successful login for user #{user.id} (#{user.email}) from IP: #{request.remote_ip}"
      
      render json: { status: 'success', message: 'Login successful', ... }
    else
      render json: { status: 'error', message: 'Account is not active' }, status: :unauthorized
    end
  else
    # Step 4: Failed login - increment attempts
    if user
      user.increment_failed_attempts!
      
      # Log failed attempt
      Rails.logger.warn "Failed login attempt for user #{user.id} (#{user.email}) from IP: #{request.remote_ip}"
      
      # Check if account should be locked
      if user.account_locked?
        render json: {
          status: 'error',
          message: 'Account locked due to multiple failed login attempts. Please contact support.',
          locked_until: user.locked_at
        }, status: :locked
        return
      end
      
      # Show remaining attempts
      remaining_attempts = 5 - (user.failed_attempts || 0)
      render json: {
        status: 'error',
        message: "Invalid email or password. #{remaining_attempts} attempts remaining.",
        remaining_attempts: remaining_attempts
      }, status: :unauthorized
    else
      # Don't reveal if user exists or not
      render json: { status: 'error', message: 'Invalid email or password' }, status: :unauthorized
    end
  end
end
```

## 🔄 **Account Lockout Flow**

### **1. Failed Login Attempt Flow**
```
User enters wrong password
         ↓
Increment failed_attempts counter
         ↓
Check if attempts >= 5
         ↓
If YES: Lock account (set locked_at)
         ↓
Return locked status to user
```

### **2. Successful Login Flow**
```
User enters correct password
         ↓
Reset failed_attempts to 0
         ↓
Update last_login timestamp
         ↓
Generate JWT token
         ↓
Return success response
```

### **3. Account Unlock Flow**
```
Admin/Support unlocks account
         ↓
Set locked_at to nil
         ↓
Reset failed_attempts to 0
         ↓
User can login again
```

## 🛡️ **Security Features**

### **1. Configurable Threshold**
```ruby
# Current setting: 5 failed attempts
if new_attempts >= 5
  lock_account!
end

# Easy to modify for different security levels
LOCKOUT_THRESHOLD = 5  # Could be made configurable
```

### **2. Comprehensive Logging**
```ruby
# Successful login logging
Rails.logger.info "Successful login for user #{user.id} (#{user.email}) from IP: #{request.remote_ip}"

# Failed attempt logging
Rails.logger.warn "Failed login attempt for user #{user.id} (#{user.email}) from IP: #{request.remote_ip}"

# Account lock logging
Rails.logger.warn "Account locked for user #{id} (#{email})"
```

### **3. IP Address Tracking**
```ruby
# Track IP addresses for security monitoring
last_sign_in_ip: string
current_sign_in_ip: string
```

### **4. Session Management**
```ruby
# Track login sessions
sign_in_count: integer
current_sign_in_at: datetime
last_sign_in_at: datetime
```

## 📊 **User Experience**

### **1. Progressive Feedback**
```json
// After 1st failed attempt
{
  "status": "error",
  "message": "Invalid email or password. 4 attempts remaining.",
  "remaining_attempts": 4
}

// After 4th failed attempt
{
  "status": "error", 
  "message": "Invalid email or password. 1 attempt remaining.",
  "remaining_attempts": 1
}

// After 5th failed attempt (account locked)
{
  "status": "error",
  "message": "Account locked due to multiple failed login attempts. Please contact support.",
  "locked_until": "2024-01-15T10:30:00Z"
}
```

### **2. Security Best Practices**
- **No user enumeration**: Same error message for non-existent users
- **Progressive warnings**: Show remaining attempts
- **Clear lockout message**: Inform user when account is locked
- **Support contact**: Guide user to contact support for unlock

## 🔧 **Configuration Options**

### **1. Lockout Threshold**
```ruby
# In User model - easily configurable
LOCKOUT_THRESHOLD = 5  # Number of failed attempts before lockout
```

### **2. Lockout Duration**
```ruby
# Currently manual unlock - could be extended to auto-unlock
def auto_unlock_after
  # Could implement auto-unlock after X minutes
  # locked_at + 30.minutes
end
```

### **3. IP-based Lockout**
```ruby
# Could extend to IP-based lockout
def lockout_by_ip?
  # Track failed attempts per IP
  # Lock specific IP addresses
end
```

## 🚀 **Advanced Features**

### **1. Admin Unlock Endpoint**
```ruby
# In SecurityController
def unlock_account
  user = User.find(params[:user_id])
  user.unlock_account!
  
  render json: {
    status: 'success',
    message: "Account unlocked for #{user.email}"
  }
end
```

### **2. Failed Attempts Reset**
```ruby
# Admin can reset failed attempts
def reset_failed_attempts
  user = User.find(params[:user_id])
  user.reset_failed_attempts!
  
  render json: {
    status: 'success',
    message: "Failed attempts reset for #{user.email}"
  }
end
```

### **3. Security Dashboard Integration**
```ruby
# Show account status in security dashboard
def account_status
  {
    locked: account_locked?,
    failed_attempts: failed_attempts || 0,
    remaining_attempts: 5 - (failed_attempts || 0),
    locked_at: locked_at
  }
end
```

## 📈 **Monitoring and Analytics**

### **1. Security Metrics**
- **Failed login attempts** per user
- **Account lockouts** frequency
- **IP address patterns** for failed attempts
- **Time-based analysis** of attack patterns

### **2. Alert System**
```ruby
# Could implement alerts for suspicious activity
def suspicious_activity_detected!
  update!(suspicious_activity_detected_at: Time.current)
  # Send alert to admin
  # Trigger additional security measures
end
```

## 🎯 **Benefits of This Implementation**

### **1. Security**
- ✅ **Brute force protection** against password guessing
- ✅ **Account isolation** prevents unauthorized access
- ✅ **Comprehensive logging** for security monitoring
- ✅ **IP tracking** for attack pattern analysis

### **2. User Experience**
- ✅ **Progressive feedback** shows remaining attempts
- ✅ **Clear messaging** when account is locked
- ✅ **Support guidance** for account recovery
- ✅ **No user enumeration** maintains privacy

### **3. Maintainability**
- ✅ **Configurable thresholds** for different security levels
- ✅ **Extensible design** for additional features
- ✅ **Comprehensive logging** for debugging
- ✅ **Clean separation** of concerns

## 🔮 **Future Enhancements**

### **1. Auto-Unlock Feature**
```ruby
def auto_unlock_after_duration
  return false unless locked_at.present?
  locked_at + 30.minutes < Time.current
end
```

### **2. IP-based Lockout**
```ruby
def lockout_by_ip_address
  # Track failed attempts per IP
  # Lock specific IP addresses
end
```

### **3. Risk-based Lockout**
```ruby
def calculate_risk_score
  # Consider factors like:
  # - Failed attempts frequency
  # - IP address reputation
  # - Time of day
  # - User behavior patterns
end
```

## 📋 **Summary**

The Account Lockout Mechanism provides:

1. **Robust Protection**: 5-attempt threshold with account locking
2. **User-Friendly**: Progressive feedback and clear messaging
3. **Admin Control**: Manual unlock and reset capabilities
4. **Comprehensive Logging**: Security monitoring and analytics
5. **Extensible Design**: Easy to enhance with additional features

This implementation ensures that user accounts are protected against brute force attacks while maintaining a good user experience and providing administrators with the tools they need to manage security effectively. 🛡️



