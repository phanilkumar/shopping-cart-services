#!/bin/bash

# Admin User Creation Script for Docker
echo "🔧 Creating Admin User via Docker"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Creating admin user via Rails console...${NC}"

# Create admin user using Rails console
docker-compose exec -T user-service bin/rails runner "
begin
  # Check if admin user already exists
  admin = User.find_by(email: 'admin@ecommerce.com')
  
  if admin
    puts '✅ Admin user already exists:'
    puts '   Email: #{admin.email}'
    puts '   Role: #{admin.role}'
    puts '   User Type: #{admin.user_type}'
    
    # Update password if needed
    if admin.authenticate('password123')
      puts '   Password: Already set to password123'
    else
      admin.update(password: 'password123', password_confirmation: 'password123')
      puts '   Password: Updated to password123'
    end
  else
    # Create new admin user
    admin = User.create!(
      email: 'admin@ecommerce.com',
      password: 'password123',
      password_confirmation: 'password123',
      user_type: 'admin',
      role: 'admin',
      first_name: 'Admin',
      last_name: 'User',
      phone: '+919876543214',
      phone_verified: true,
      email_verified: true,
      verification_status: 'verified',
      address_line1: 'Admin Office',
      address_line2: 'Floor 10',
      city: 'Chennai',
      state: 'Tamil Nadu',
      pincode: '600001',
      total_transactions: 0,
      last_login_at: Time.current
    )
    
    puts '✅ Admin user created successfully:'
    puts '   Email: #{admin.email}'
    puts '   Password: password123'
    puts '   Role: #{admin.role}'
    puts '   User Type: #{admin.user_type}'
  end
  
  puts ''
  puts '🎉 Admin user setup completed!'
  puts ''
  puts '📊 User Statistics:'
  puts '   Total users: #{User.count}'
  puts '   Admin users: #{User.where(user_type: \"admin\").count}'
  
rescue => e
  puts '❌ Error: #{e.message}'
  puts '   Trying alternative method...'
  
  # Try with minimal data
  admin = User.create!(
    email: 'admin@ecommerce.com',
    password: 'password123',
    password_confirmation: 'password123',
    user_type: 'admin',
    role: 'admin',
    first_name: 'Admin',
    last_name: 'User'
  )
  
  puts '✅ Admin user created with minimal data:'
  puts '   Email: #{admin.email}'
  puts '   Password: password123'
end
"

echo ""
echo -e "${GREEN}🎉 Admin User Setup Instructions:${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}🔑 Admin Credentials:${NC}"
echo "   Email: admin@ecommerce.com"
echo "   Password: password123"
echo ""
echo -e "${BLUE}🌐 Access Admin Dashboard:${NC}"
echo "   URL: http://localhost:3008"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Open browser and go to: http://localhost:3008"
echo "2. Enter the credentials above"
echo "3. Click 'Sign In'"
echo ""
echo -e "${GREEN}✅ Script completed!${NC}"




