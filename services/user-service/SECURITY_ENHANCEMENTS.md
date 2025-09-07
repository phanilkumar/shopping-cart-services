# Security Enhancements for User Service

This document outlines the comprehensive security enhancements implemented for the registration and login functionalities in the User Service.

## Overview

The User Service has been enhanced with multiple layers of security to protect against common attack vectors and ensure robust authentication and authorization mechanisms.

## Security Features Implemented

### 1. Rate Limiting and Brute Force Protection

**Implementation**: Rack::Attack middleware
**Location**: `config/initializers/rack_attack.rb`

- **Login Rate Limiting**: 5 attempts per IP per 20 seconds
- **Registration Rate Limiting**: 3 attempts per IP per hour
- **Password Reset Rate Limiting**: 3 attempts per IP per hour
- **OTP Rate Limiting**: 5 attempts per IP per hour
- **API Rate Limiting**: 100 requests per IP per minute
- **Per-Email/Phone Rate Limiting**: 5 failed attempts per 20 seconds

**Features**:
- Blocks suspicious user agents (bots, crawlers, scrapers)
- Blocks SQL injection patterns
- Custom throttling responses with retry-after headers
- Comprehensive logging of security events

### 2. Account Lockout Mechanism

**Implementation**: Devise lockable module + custom logic
**Location**: `app/models/user.rb`, `config/initializers/devise.rb`

- **Lockout Threshold**: 5 failed login attempts
- **Lockout Duration**: 1 hour (automatic unlock)
- **Manual Unlock**: Admin can unlock accounts
- **Failed Attempt Tracking**: Persistent across sessions

**Features**:
- Automatic account locking after failed attempts
- Time-based automatic unlocking
- Admin override capabilities
- Detailed logging of lockout events

### 3. Enhanced Password Security

**Implementation**: Custom validation + Strong Password gem
**Location**: `app/models/user.rb`, `app/javascript/controllers/password_strength_controller.js`

**Password Requirements**:
- Minimum length: 8 characters
- Maximum length: 16 characters
- Must contain at least one letter
- Must contain at least one number
- Must contain at least one special character
- Must not be a common password
- Real-time strength validation

**Features**:
- Real-time password strength indicator
- Visual feedback for requirements
- Common password detection
- Client-side and server-side validation

### 4. Two-Factor Authentication (2FA)

**Implementation**: ROTP gem + custom controller
**Location**: `app/controllers/security_controller.rb`, `app/models/user.rb`

**Features**:
- TOTP (Time-based One-Time Password) implementation
- QR code generation for authenticator apps
- Manual setup with secret key
- 30-second drift tolerance
- Enable/disable functionality
- Secure secret generation

### 5. Security Headers

**Implementation**: Application controller
**Location**: `app/controllers/application_controller.rb`

**Headers Implemented**:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Content-Security-Policy`: Comprehensive CSP
- `Strict-Transport-Security`: HSTS for HTTPS
- `Server`: Custom server header

### 6. Audit Logging

**Implementation**: Audited gem + custom logging
**Location**: `app/models/user.rb`, `app/controllers/`

**Logged Events**:
- User registration
- Successful logins
- Failed login attempts
- Account lockouts
- Password changes
- 2FA enable/disable
- Admin actions

**Features**:
- Comprehensive audit trail
- IP address tracking
- User agent logging
- Timestamp recording
- Sensitive data exclusion

### 7. Session Security

**Implementation**: Devise + custom configuration
**Location**: `config/initializers/devise.rb`

**Features**:
- Session timeout: 30 minutes
- Secure session storage
- CSRF protection
- Remember me functionality
- Automatic session cleanup

### 8. Input Validation and Sanitization

**Implementation**: Model validations + client-side validation
**Location**: `app/models/user.rb`, `app/views/`

**Validation Features**:
- Email format validation
- Phone number validation (Indian format)
- Name validation (letters only)
- Input length limits
- XSS prevention
- SQL injection prevention

### 9. JWT Token Security

**Implementation**: JWT gem + custom logic
**Location**: `app/models/user.rb`, `app/controllers/auth/auth_controller.rb`

**Features**:
- Secure token generation
- Token expiration (24 hours)
- Refresh token mechanism
- JTI (JWT ID) for token tracking
- Account lockout integration

### 10. Security Dashboard

**Implementation**: Custom controller and view
**Location**: `app/controllers/security_controller.rb`, `app/views/security/dashboard.html.erb`

**Features**:
- Real-time security status
- 2FA setup interface
- Security recommendations
- Activity monitoring
- Account status overview

## API Security

### Authentication Endpoints

1. **POST /api/v1/auth/login**
   - Rate limited
   - Account lockout protection
   - Failed attempt tracking
   - Secure error messages

2. **POST /api/v1/auth/register**
   - Rate limited
   - Input validation
   - Password strength validation
   - Audit logging

3. **POST /api/v1/auth/refresh**
   - Token validation
   - Account status check
   - Secure token refresh

### Security Endpoints

1. **GET /security/status**
   - Account security overview
   - 2FA status
   - Login history

2. **POST /security/enable-2fa**
   - 2FA setup
   - QR code generation
   - Secret key generation

3. **POST /security/verify-otp**
   - OTP verification
   - 2FA activation

## Configuration

### Environment Variables

```bash
# JWT Configuration
JWT_SECRET_KEY=your-secure-jwt-secret

# Redis Configuration (for rate limiting)
REDIS_URL=redis://localhost:6379/0

# Security Settings
RACK_ATTACK_ENABLED=true
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=3600
```

### Database Configuration

The following security-related fields have been added to the users table:

- `failed_attempts`: Track failed login attempts
- `locked_at`: Account lockout timestamp
- `unlock_token`: Account unlock token
- `two_factor_secret`: 2FA secret key
- `two_factor_enabled`: 2FA status
- `last_sign_in_ip`: Last login IP
- `current_sign_in_ip`: Current session IP
- `sign_in_count`: Total login count
- `current_sign_in_at`: Current session start
- `last_sign_in_at`: Last session start
- `timeout_in`: Session timeout duration
- `password_changed_at`: Password change timestamp
- `password_expires_at`: Password expiration
- `suspicious_activity_detected_at`: Suspicious activity flag
- `security_questions_answered`: Security questions status

## Monitoring and Alerting

### Log Monitoring

Monitor the following log patterns for security events:

```bash
# Failed login attempts
grep "Failed login attempt" log/development.log

# Account lockouts
grep "Account locked" log/development.log

# Rate limiting events
grep "Rack::Attack" log/development.log

# Successful logins
grep "Successful login" log/development.log
```

### Security Metrics

Track the following security metrics:

- Failed login attempts per hour
- Account lockouts per day
- Rate limiting events per hour
- 2FA adoption rate
- Password strength distribution

## Best Practices

### For Developers

1. **Never log sensitive data**: Passwords, tokens, or personal information
2. **Use HTTPS in production**: Always enforce SSL/TLS
3. **Regular security audits**: Review security logs and metrics
4. **Keep dependencies updated**: Regularly update security-related gems
5. **Test security features**: Include security tests in your test suite

### For Administrators

1. **Monitor security logs**: Set up log monitoring and alerting
2. **Regular backups**: Ensure secure backup of audit logs
3. **Access control**: Limit admin access to security features
4. **Incident response**: Have a plan for security incidents
5. **User education**: Educate users about security features

### For Users

1. **Enable 2FA**: Use two-factor authentication
2. **Strong passwords**: Use unique, strong passwords
3. **Monitor activity**: Check login history regularly
4. **Report suspicious activity**: Report any unusual account activity
5. **Keep devices secure**: Ensure devices are secure and updated

## Security Testing

### Manual Testing

1. **Rate Limiting Test**:
   ```bash
   # Test login rate limiting
   for i in {1..10}; do curl -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"wrong"}' && echo; done
   ```

2. **Account Lockout Test**:
   - Attempt 5 failed logins
   - Verify account is locked
   - Wait for automatic unlock
   - Test admin unlock functionality

3. **2FA Test**:
   - Enable 2FA
   - Scan QR code with authenticator app
   - Verify OTP code
   - Test login with 2FA

### Automated Testing

Run the security test suite:

```bash
bundle exec rspec spec/security/
```

## Incident Response

### Security Incident Checklist

1. **Immediate Response**:
   - Identify the type of incident
   - Assess the scope and impact
   - Take immediate containment actions

2. **Investigation**:
   - Review security logs
   - Analyze attack patterns
   - Identify affected accounts

3. **Remediation**:
   - Reset affected accounts
   - Update security measures
   - Notify affected users

4. **Post-Incident**:
   - Document lessons learned
   - Update security procedures
   - Conduct security review

## Compliance

This implementation addresses the following security requirements:

- **OWASP Top 10**: Protection against common web vulnerabilities
- **GDPR**: Data protection and privacy requirements
- **SOC 2**: Security controls and monitoring
- **PCI DSS**: Payment card industry security standards

## Future Enhancements

Planned security improvements:

1. **Advanced Threat Detection**: Machine learning-based anomaly detection
2. **Biometric Authentication**: Fingerprint and face recognition
3. **Hardware Security Keys**: FIDO2/U2F support
4. **Advanced Monitoring**: Real-time threat intelligence
5. **Compliance Reporting**: Automated compliance reporting

## Support

For security-related issues or questions:

1. **Security Issues**: Report via security@example.com
2. **Documentation**: Check this document and code comments
3. **Updates**: Monitor security advisories and updates
4. **Training**: Request security training sessions

---

**Last Updated**: January 2025
**Version**: 1.0
**Maintainer**: Security Team



