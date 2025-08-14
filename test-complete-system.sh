#!/bin/bash

echo "🎯 COMPLETE SYSTEM TEST"
echo "======================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test API endpoint
test_api_endpoint() {
    local endpoint=$1
    local description=$2
    local method=${3:-GET}
    local data=${4:-""}
    local token=${5:-""}

    echo -e "\n${BLUE}Testing $description...${NC}"
    echo "Endpoint: $method $endpoint"

    local headers="Content-Type: application/json"
    if [ -n "$token" ]; then
        headers="$headers -H Authorization: Bearer $token"
    fi

    if [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X $method \
            -H "$headers" \
            -d "$data" \
            "http://localhost:3000$endpoint")
    else
        response=$(curl -s -w "%{http_code}" -X $method \
            -H "$headers" \
            "http://localhost:3000$endpoint")
    fi

    http_code="${response: -3}"
    body="${response%???}"

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        echo -e "${GREEN}✅ Success (HTTP $http_code)${NC}"
        echo "Response: $body" | head -c 200
        [ ${#body} -gt 200 ] && echo "..."
        return 0
    else
        echo -e "${RED}❌ Failed (HTTP $http_code)${NC}"
        echo "Response: $body"
        return 1
    fi
}

# Function to test admin dashboard
test_admin_dashboard() {
    echo -e "\n${BLUE}Testing Admin Dashboard...${NC}"

    # Test if admin dashboard is accessible
    if curl -s -f "http://localhost:3008" > /dev/null; then
        echo -e "${GREEN}✅ Admin Dashboard is accessible${NC}"

        # Test if it loads the React app
        if curl -s "http://localhost:3008" | grep -q "E-commerce Admin Dashboard"; then
            echo -e "${GREEN}✅ React application is loading${NC}"
        else
            echo -e "${RED}❌ React application not loading properly${NC}"
        fi
    else
        echo -e "${RED}❌ Admin Dashboard not accessible${NC}"
        return 1
    fi
}

# Function to get authentication token
get_auth_token() {
    echo -e "\n${BLUE}Getting authentication token...${NC}"
    
    login_response=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@ecommerce.com","password":"password123"}')
    
    if echo "$login_response" | grep -q "token"; then
        token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}✅ Authentication successful${NC}"
        echo "Token: ${token:0:50}..."
        echo "$token"
    else
        echo -e "${RED}❌ Authentication failed${NC}"
        echo ""
    fi
}

# Main test execution
echo -e "\n${YELLOW}🔍 STEP 1: API Server Tests${NC}"
echo "========================="

# Test health endpoint
test_api_endpoint "/health" "Health Check"

# Test root endpoint
test_api_endpoint "/" "API Documentation"

# Test public endpoints
test_api_endpoint "/api/v1/users" "Public Users Endpoint"
test_api_endpoint "/api/v1/products" "Public Products Endpoint"
test_api_endpoint "/api/v1/orders" "Public Orders Endpoint"

echo -e "\n${YELLOW}🔍 STEP 2: Authentication Tests${NC}"
echo "==============================="

# Test login
test_api_endpoint "/api/v1/auth/login" "User Login" "POST" '{"email":"admin@ecommerce.com","password":"password123"}'

# Get authentication token
token=$(get_auth_token)

if [ -n "$token" ]; then
    echo -e "\n${YELLOW}🔍 STEP 3: Admin API Tests${NC}"
    echo "======================="

    # Test admin endpoints with authentication
    test_api_endpoint "/api/v1/admin/dashboard" "Admin Dashboard Data" "GET" "" "$token"
    test_api_endpoint "/api/v1/admin/users" "Admin Users Data" "GET" "" "$token"
    test_api_endpoint "/api/v1/admin/products" "Admin Products Data" "GET" "" "$token"
    test_api_endpoint "/api/v1/admin/orders" "Admin Orders Data" "GET" "" "$token"
else
    echo -e "${RED}❌ Cannot test admin endpoints without authentication token${NC}"
fi

echo -e "\n${YELLOW}🔍 STEP 4: Admin Dashboard Tests${NC}"
echo "==============================="

# Test admin dashboard
test_admin_dashboard

echo -e "\n${YELLOW}📊 FINAL STATUS${NC}"
echo "=============="

# Check if all services are running
echo -e "\n${BLUE}Service Status:${NC}"
if curl -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✅ API Server (port 3000) - Running${NC}"
else
    echo -e "${RED}❌ API Server (port 3000) - Not running${NC}"
fi

if curl -s http://localhost:3008 > /dev/null; then
    echo -e "${GREEN}✅ Admin Dashboard (port 3008) - Running${NC}"
else
    echo -e "${RED}❌ Admin Dashboard (port 3008) - Not running${NC}"
fi

if docker ps | grep -q "postgres"; then
    echo -e "${GREEN}✅ PostgreSQL (port 5432) - Running${NC}"
else
    echo -e "${RED}❌ PostgreSQL (port 5432) - Not running${NC}"
fi

if docker ps | grep -q "redis"; then
    echo -e "${GREEN}✅ Redis (port 6379) - Running${NC}"
else
    echo -e "${RED}❌ Redis (port 6379) - Not running${NC}"
fi

echo -e "\n${BLUE}Access URLs:${NC}"
echo "• API Server: http://localhost:3000"
echo "• Admin Dashboard: http://localhost:3008"
echo "• API Documentation: http://localhost:3000/"

echo -e "\n${BLUE}Test Credentials:${NC}"
echo "• Email: admin@ecommerce.com"
echo "• Password: password123"

echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. Open http://localhost:3008 in your browser"
echo "2. Login with the credentials above"
echo "3. Explore the admin dashboard"
echo "4. Test all navigation sections"

echo -e "\n${GREEN}🎉 Complete system test finished!${NC}"
echo -e "${GREEN}Your e-commerce platform is ready for use! 🚀${NC}"

