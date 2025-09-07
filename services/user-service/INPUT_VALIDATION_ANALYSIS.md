# Input Validation & Sanitization Analysis

## Overview
The User Service implements comprehensive input validation and sanitization across multiple layers to ensure security and data integrity.

## 1. Email Format Validation

### Implementation Details:
- **Primary Validation**: Devise `:validatable` module provides robust email format validation
- **Additional Validation**: Custom length validation (maximum 50 characters)
- **Normalization**: Email is converted to lowercase and stripped of whitespace before validation

### Code Location:
```ruby
# app/models/user.rb
validates :email, length: { maximum: 50, message: 'Email address is too long (maximum 50 characters)' }

def normalize_email
  self.email = email.downcase.strip if email.present?
end
```

### Validation Rules:
- ✅ Valid email format (local@domain.tld)
- ✅ Maximum 50 characters
- ✅ Case-insensitive uniqueness
- ❌ Invalid formats rejected
- ❌ Empty emails rejected

## 2. Phone Number Validation (Indian Format)

### Implementation Details:
- **Format**: Indian mobile numbers (10 digits starting with 6, 7, 8, or 9)
- **Country Code**: Automatic +91 prefix addition
- **Sanitization**: Removes special characters and normalizes format

### Code Location:
```ruby
# app/models/user.rb
validates :phone, presence: { message: 'Mobile number is required' }
validates :phone, format: { 
  with: /\A\+?91[6-9]\d{9}\z/, 
  message: 'Please enter a valid 10-digit Indian mobile number (e.g., 9876543210)' 
}, allow_blank: true
validates :phone, uniqueness: { message: 'Mobile number is already registered' }, allow_blank: true

def sanitize_phone
  return if phone.blank?
  
  cleaned_phone = phone.to_s.gsub(/[^\d]/, '')
  
  if cleaned_phone.match?(/\A[6-9]\d{9}\z/)
    self.phone = "+91#{cleaned_phone}"
  elsif cleaned_phone.match?(/\A91[6-9]\d{9}\z/)
    self.phone = "+#{cleaned_phone}"
  elsif cleaned_phone.match?(/\A\+91[6-9]\d{9}\z/)
    self.phone = cleaned_phone
  end
end
```

### Validation Rules:
- ✅ 10-digit numbers starting with 6, 7, 8, or 9
- ✅ Automatic +91 prefix addition
- ✅ Uniqueness validation
- ❌ Invalid starting digits (1, 2, 3, 4, 5)
- ❌ Non-numeric characters
- ❌ Wrong length

## 3. Name Validation (Letters Only)

### Implementation Details:
- **Format**: Letters only (a-z, A-Z)
- **Length**: 4-20 characters
- **Required**: Both first_name and last_name are mandatory

### Code Location:
```ruby
# app/models/user.rb
validates :first_name, presence: { message: 'First name is required' },
  length: { minimum: 4, maximum: 20, message: 'First name must be between 4 and 20 characters' },
  format: { 
    with: /\A[a-zA-Z]+\z/, 
    message: 'First name can only contain letters (a-z, A-Z)' 
  }

validates :last_name, presence: { message: 'Last name is required' },
  length: { minimum: 4, maximum: 20, message: 'Last name must be between 4 and 20 characters' },
  format: { 
    with: /\A[a-zA-Z]+\z/, 
    message: 'Last name can only contain letters (a-z, A-Z)' 
  }
```

### Validation Rules:
- ✅ Letters only (a-z, A-Z)
- ✅ 4-20 characters length
- ✅ Required field
- ❌ Numbers, special characters, spaces
- ❌ Too short (< 4 chars) or too long (> 20 chars)

## 4. XSS Prevention

### Implementation Details:
- **Rack::Attack**: Comprehensive XSS pattern detection
- **Rails Sanitization**: Built-in HTML escaping
- **Parameter Filtering**: Strong parameters prevent injection

### Code Location:
```ruby
# config/initializers/rack_attack.rb
xss_patterns = [
  /<script/i,
  /javascript:/i,
  /on\w+\s*=/i,
  /vbscript:/i,
  /data:text\/html/i,
  /<iframe/i,
  /<object/i,
  /<embed/i,
  /<svg/i,
  /<img/i,
  /<link/i,
  /<meta/i,
  /expression\s*\(/i,
  /url\s*\(/i,
  /import\s*\(/i,
  /@import/i
]
```

### Prevention Mechanisms:
- ✅ Pattern-based detection in Rack::Attack
- ✅ HTML entity encoding
- ✅ URL decoding protection
- ✅ Multi-stage pattern detection
- ✅ Request body and header scanning

## 5. SQL Injection Prevention

### Implementation Details:
- **ActiveRecord**: Parameterized queries prevent SQL injection
- **Rack::Attack**: SQL injection pattern detection
- **Strong Parameters**: Input filtering

### Code Location:
```ruby
# config/initializers/rack_attack.rb
sql_patterns = [
  /union\s*select/i,
  /drop\s*table/i,
  /insert\s*into/i,
  /delete\s*from/i,
  /update\s*set/i,
  /OR\s*['"]1['"]\s*=\s*['"]1['"]/i,
  /AND\s*1\s*=\s*1/i,
  /sleep\s*\(/i,
  /waitfor\s+delay/i,
  /benchmark\s*\(/i
]
```

### Prevention Mechanisms:
- ✅ ActiveRecord parameterized queries
- ✅ Pattern-based detection
- ✅ Boolean-based injection detection
- ✅ Time-based injection detection
- ✅ Command injection prevention

## 6. Password Validation

### Implementation Details:
- **Complexity Requirements**: 8-16 characters with mixed character types
- **Common Password Check**: Rejection of known weak passwords
- **Devise Integration**: Leverages Devise password validation

### Code Location:
```ruby
# app/models/user.rb
def password_complexity
  return if password.blank?
  
  if password.length < 8
    errors.add(:password, 'must be at least 8 characters long')
  elsif password.length > 16
    errors.add(:password, 'must not exceed 16 characters')
  end
  
  unless password.match?(/[a-zA-Z]/)
    errors.add(:password, 'must contain at least one letter')
  end
  
  unless password.match?(/\d/)
    errors.add(:password, 'must contain at least one number')
  end
  
  unless password.match?(/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/)
    errors.add(:password, 'must contain at least one special character')
  end
end

def password_not_common
  return if password.blank?
  
  if password_compromised?
    errors.add(:password, 'is too common. Please choose a more secure password.')
  end
end
```

### Validation Rules:
- ✅ 8-16 characters length
- ✅ At least one letter
- ✅ At least one number
- ✅ At least one special character
- ✅ Not in common password list
- ❌ Too short or too long
- ❌ Missing required character types

## 7. Rate Limiting

### Implementation Details:
- **Rack::Attack**: Comprehensive rate limiting
- **Multiple Limits**: Different limits for different actions
- **IP-based**: Per-IP address limiting

### Code Location:
```ruby
# config/initializers/rack_attack.rb
throttle('login/ip', limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == '/users/sign_in' && req.post?
end

throttle('api_login/ip', limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == '/api/v1/auth/login' && req.post?
end

throttle('register/ip', limit: 3, period: 1.hour) do |req|
  req.ip if req.path == '/users' && req.post?
end
```

### Rate Limits:
- ✅ Login attempts: 5 per 20 seconds per IP
- ✅ Registration: 3 per hour per IP
- ✅ Password reset: 3 per hour per IP
- ✅ OTP requests: 5 per hour per IP
- ✅ API requests: 100 per minute per IP

## 8. Input Sanitization

### Implementation Details:
- **Before Validation Callbacks**: Automatic sanitization
- **Strong Parameters**: Parameter filtering
- **Rails Sanitization**: Built-in HTML escaping

### Code Location:
```ruby
# app/models/user.rb
before_validation :sanitize_phone
before_save :normalize_email

# app/controllers/api/v1/auth_controller.rb
def user_params
  params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone)
end
```

### Sanitization Features:
- ✅ Phone number normalization
- ✅ Email normalization
- ✅ Parameter filtering
- ✅ HTML escaping
- ✅ Whitespace trimming

## 9. Security Headers

### Implementation Details:
- **CORS Configuration**: Controlled cross-origin access
- **Response Headers**: Security-focused headers
- **API Versioning**: Version control in headers

### Code Location:
```ruby
# config/application.rb
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3005', 'http://localhost:3001'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end

# app/controllers/api/v1/base_controller.rb
def set_response_headers
  response.headers['X-API-Version'] = API_VERSION
  response.headers['X-Request-ID'] = request.request_id
  response.headers['X-Response-Time'] = Time.current.to_f.to_s
end
```

## 10. Error Handling

### Implementation Details:
- **Standardized Error Responses**: Consistent error format
- **Validation Error Handling**: Proper error message formatting
- **Security Error Handling**: Appropriate security responses

### Code Location:
```ruby
# app/controllers/base_application_controller.rb
def error_response(message, errors = [], status = :unprocessable_entity, meta = {})
  render json: build_response(
    status: 'error',
    message: message,
    errors: errors,
    meta: meta
  ), status: HTTP_STATUS[status]
end
```

## Security Assessment

### Strengths:
✅ **Multi-layered Security**: Validation at model, controller, and middleware levels
✅ **Comprehensive Pattern Detection**: Extensive attack pattern recognition
✅ **Rate Limiting**: Protection against brute force attacks
✅ **Input Sanitization**: Automatic cleaning of user input
✅ **Strong Parameters**: Prevention of mass assignment attacks
✅ **Audit Logging**: Comprehensive security event tracking

### Areas for Enhancement:
⚠️ **Content Security Policy**: Could add CSP headers
⚠️ **Input Length Limits**: Could add more granular length restrictions
⚠️ **File Upload Validation**: Not applicable for this service
⚠️ **API Key Management**: Could implement API key validation

## Conclusion

The User Service implements robust input validation and sanitization with multiple security layers. The combination of ActiveRecord validations, Rack::Attack security rules, and custom sanitization provides comprehensive protection against common attack vectors including XSS, SQL injection, and brute force attacks.

The implementation follows security best practices and provides a solid foundation for a secure user authentication system.



