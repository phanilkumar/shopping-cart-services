# Secure Headers Configuration
# Configure security headers for the application

SecureHeaders::Configuration.default do |config|
  # X-Frame-Options: Prevents clickjacking
  config.x_frame_options = "DENY"
  
  # X-Content-Type-Options: Prevents MIME sniffing
  config.x_content_type_options = "nosniff"
  
  # X-XSS-Protection: XSS protection
  config.x_xss_protection = "1; mode=block"
  
  # X-Download-Options: Prevents IE from executing downloads
  config.x_download_options = "noopen"
  
  # X-Permitted-Cross-Domain-Policies: Controls Adobe Flash and Adobe Acrobat
  config.x_permitted_cross_domain_policies = "none"
  
  # Referrer-Policy: Controls referrer information
  config.referrer_policy = "strict-origin-when-cross-origin"
  
  # Strict-Transport-Security: Enforces HTTPS
  config.hsts = "max-age=31536000; includeSubDomains; preload"
  
  # Content-Security-Policy: Controls resource loading
  config.csp = {
    # Default directive
    default_src: %w('self'),
    
    # Script sources
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net),
    
    # Style sources
    style_src: %w('self' 'unsafe-inline' https://cdn.jsdelivr.net data:),
    
    # Image sources
    img_src: %w('self' data: https:),
    
    # Font sources
    font_src: %w('self' https:),
    
    # Connect sources (for AJAX)
    connect_src: %w('self'),
    
    # Media sources
    media_src: %w('self'),
    
    # Object sources
    object_src: %w('none'),
    
    # Frame sources
    frame_src: %w('none'),
    
    # Worker sources
    worker_src: %w('self'),
    
    # Manifest sources
    manifest_src: %w('self'),
    
    # Form action
    form_action: %w('self'),
    
    # Base URI
    base_uri: %w('self'),
    
    # Upgrade insecure requests
    upgrade_insecure_requests: true
  }
  
  # Clear-Site-Data: Clears site data on logout
  config.clear_site_data = %w(cache cookies storage)
end

# Configure secure headers for API endpoints
SecureHeaders::Configuration.override(:api) do |config|
  # Less restrictive CSP for API endpoints
  config.csp = {
    default_src: %w('self'),
    script_src: %w('self'),
    style_src: %w('self'),
    img_src: %w('self' data:),
    font_src: %w('self'),
    connect_src: %w('self'),
    media_src: %w('self'),
    object_src: %w('none'),
    frame_src: %w('none'),
    worker_src: %w('self'),
    manifest_src: %w('self'),
    form_action: %w('self'),
    base_uri: %w('self')
  }
end
