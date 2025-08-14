#!/bin/bash

# Auth Service API Test Script
# This script tests all endpoints of the Auth Service

BASE_URL="http://localhost:3000"
API_BASE="$BASE_URL/api/v1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to make HTTP requests and check response
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4
    local description=$5
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$endpoint")
    else
        response=$(curl -s -w "%{http_code}" -o /tmp/response.json -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" "$endpoint")
    fi
    
    http_code="${response: -3}"
    
    if [ "$http_code" = "$expected_status" ]; then
        print_result 0 "$description"
        if [ -f /tmp/response.json ]; then
            echo "Response: $(cat /tmp/response.json | head -c 200)..."
        fi
    else
        print_result 1 "$description (Expected: $expected_status, Got: $http_code)"
        if [ -f /tmp/response.json ]; then
            echo "Response: $(cat /tmp/response.json)"
        fi
    fi
}

# Start the Rails server in background
echo -e "${YELLOW}Starting Auth Service server...${NC}"
rails server -p 3000 -d

# Wait for server to start
sleep 5

print_section "Health Check Tests"
test_endpoint "GET" "$BASE_URL/health" "" "200" "Health check endpoint"

print_section "Authentication Tests"

# Test user registration
echo -e "\n${YELLOW}Testing User Registration...${NC}"
REGISTER_DATA='{
    "user": {
        "email": "test@example.com",
        "password": "password123",
        "password_confirmation": "password123",
        "first_name": "John",
        "last_name": "Doe",
        "phone": "+1234567890"
    }
}'
test_endpoint "POST" "$API_BASE/auth/register" "$REGISTER_DATA" "201" "User registration"

# Test user login
echo -e "\n${YELLOW}Testing User Login...${NC}"
LOGIN_DATA='{
    "email": "test@example.com",
    "password": "password123"
}'
test_endpoint "POST" "$API_BASE/auth/login" "$LOGIN_DATA" "200" "User login"

# Extract token from login response for subsequent tests
if [ -f /tmp/response.json ]; then
    TOKEN=$(cat /tmp/response.json | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$TOKEN" ]; then
        echo -e "${GREEN}Token extracted: ${TOKEN:0:20}...${NC}"
    fi
fi

print_section "User Management Tests"

# Test get user profile (requires authentication)
if [ -n "$TOKEN" ]; then
    echo -e "\n${YELLOW}Testing User Profile (with authentication)...${NC}"
    test_endpoint "GET" "$API_BASE/users/1" "" "200" "Get user profile (authenticated)"
    
    # Test update user
    UPDATE_DATA='{
        "user": {
            "first_name": "Jane",
            "last_name": "Smith"
        }
    }'
    test_endpoint "PUT" "$API_BASE/users/1" "$UPDATE_DATA" "200" "Update user profile"
    
    # Test get user profile endpoint
    test_endpoint "GET" "$API_BASE/users/1/profile" "" "200" "Get user profile details"
else
    echo -e "${RED}No token available for authenticated tests${NC}"
fi

print_section "Password Management Tests"

# Test forgot password
echo -e "\n${YELLOW}Testing Password Reset...${NC}"
FORGOT_DATA='{
    "email": "test@example.com"
}'
test_endpoint "POST" "$API_BASE/password/forgot" "$FORGOT_DATA" "200" "Forgot password request"

# Test password reset (with mock token)
RESET_DATA='{
    "token": "mock_reset_token",
    "password": "newpassword123",
    "password_confirmation": "newpassword123"
}'
test_endpoint "POST" "$API_BASE/password/reset" "$RESET_DATA" "200" "Password reset"

print_section "Error Handling Tests"

# Test invalid login
echo -e "\n${YELLOW}Testing Error Cases...${NC}"
INVALID_LOGIN='{
    "email": "invalid@example.com",
    "password": "wrongpassword"
}'
test_endpoint "POST" "$API_BASE/auth/login" "$INVALID_LOGIN" "401" "Invalid login credentials"

# Test invalid registration
INVALID_REGISTER='{
    "user": {
        "email": "invalid-email",
        "password": "short",
        "password_confirmation": "short"
    }
}'
test_endpoint "POST" "$API_BASE/auth/register" "$INVALID_REGISTER" "422" "Invalid registration data"

# Test unauthorized access
test_endpoint "GET" "$API_BASE/users/1" "" "401" "Unauthorized access to user profile"

print_section "Token Management Tests"

# Test token refresh (if we have a refresh token)
if [ -f /tmp/response.json ]; then
    REFRESH_TOKEN=$(cat /tmp/response.json | grep -o '"refresh_token":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$REFRESH_TOKEN" ]; then
        REFRESH_DATA="{\"refresh_token\":\"$REFRESH_TOKEN\"}"
        test_endpoint "POST" "$API_BASE/auth/refresh" "$REFRESH_DATA" "200" "Token refresh"
    fi
fi

# Test logout
test_endpoint "DELETE" "$API_BASE/auth/logout" "" "200" "User logout"

print_section "Test Summary"
echo -e "\n${BLUE}Test Results:${NC}"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}Total Tests: $((TESTS_PASSED + TESTS_FAILED))${NC}"

# Stop the Rails server
echo -e "\n${YELLOW}Stopping Auth Service server...${NC}"
pkill -f "rails server"

# Cleanup
rm -f /tmp/response.json

echo -e "\n${GREEN}Auth Service testing completed!${NC}"
