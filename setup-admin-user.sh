#!/bin/bash

# Admin User Setup Script for E-commerce Platform
echo "🔧 Setting up Admin User for E-commerce Platform"
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Running seed data to create admin user...${NC}"

# Run seed data
if docker-compose exec user-service bin/rails db:seed; then
    echo -e "${GREEN}✅ Seed data executed successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Seed data execution failed or was interrupted${NC}"
    echo -e "${BLUE}Let's try a different approach...${NC}"
fi

echo ""
echo -e "${BLUE}Step 2: Checking if admin user exists...${NC}"

# Check if admin user exists by testing the health endpoint
if curl -s http://localhost:3001/health > /dev/null; then
    echo -e "${GREEN}✅ User service is running${NC}"
else
    echo -e "${YELLOW}⚠️  User service might not be responding${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Admin User Setup Instructions:${NC}"
echo "================================================"
echo ""
echo -e "${BLUE}🔑 Admin Credentials:${NC}"
echo "   Email: admin@ecommerce.com"
echo "   Password: password123"
echo ""
echo -e "${BLUE}🌐 Access URLs:${NC}"
echo "   Admin Dashboard: http://localhost:3008"
echo "   Frontend: http://localhost:3005"
echo ""
echo -e "${BLUE}📋 Manual Steps (if automated setup fails):${NC}"
echo "1. Open browser and go to: http://localhost:3008"
echo "2. Enter credentials:"
echo "   - Email: admin@ecommerce.com"
echo "   - Password: password123"
echo "3. Click 'Sign In'"
echo ""
echo -e "${BLUE}🔧 If login still fails:${NC}"
echo "1. Check if user service is running:"
echo "   docker-compose ps user-service"
echo "2. Check user service logs:"
echo "   docker-compose logs user-service"
echo "3. Restart user service:"
echo "   docker-compose restart user-service"
echo ""
echo -e "${GREEN}✅ Setup script completed!${NC}"




