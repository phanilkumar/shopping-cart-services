-- Add admin user to the user_service_dev database
INSERT INTO users (
  email, 
  first_name, 
  last_name, 
  phone, 
  encrypted_password, 
  role, 
  status, 
  email_verified_at, 
  created_at, 
  updated_at
) VALUES (
  'admin@example.com',
  'Admin',
  'User',
  '+919876543210',
  '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK2', -- password: admin123
  1, -- admin role
  1, -- active status
  NOW(),
  NOW(),
  NOW()
);
