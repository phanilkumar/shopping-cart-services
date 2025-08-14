#!/bin/bash

# OAuth Service API Test Script
# This script tests all endpoints of the OAuth Service

BASE_URL="http://localhost:3001"
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
echo -e "${YELLOW}Starting OAuth Service server...${NC}"
rails server -p 3001 -d

# Wait for server to start
sleep 5

print_section "Health Check Tests"
test_endpoint "GET" "$BASE_URL/health" "" "200" "Health check endpoint"

print_section "OAuth Provider Tests"

# Test Google OAuth redirect
echo -e "\n${YELLOW}Testing OAuth Provider Redirects...${NC}"
test_endpoint "GET" "$API_BASE/oauth/google" "" "200" "Google OAuth redirect"

# Test Facebook OAuth redirect
test_endpoint "GET" "$API_BASE/oauth/facebook" "" "200" "Facebook OAuth redirect"

# Test GitHub OAuth redirect
test_endpoint "GET" "$API_BASE/oauth/github" "" "200" "GitHub OAuth redirect"

# Test Twitter OAuth redirect
test_endpoint "GET" "$API_BASE/oauth/twitter" "" "200" "Twitter OAuth redirect"

# Test LinkedIn OAuth redirect
test_endpoint "GET" "$API_BASE/oauth/linkedin" "" "200" "LinkedIn OAuth redirect"

print_section "OAuth Callback Tests"

# Test OAuth callback with mock data
echo -e "\n${YELLOW}Testing OAuth Callback...${NC}"
test_endpoint "GET" "$API_BASE/oauth/callback?provider=google" "" "200" "Google OAuth callback"

# Test callback with different providers
test_endpoint "GET" "$API_BASE/oauth/callback?provider=facebook" "" "200" "Facebook OAuth callback"
test_endpoint "GET" "$API_BASE/oauth/callback?provider=github" "" "200" "GitHub OAuth callback"
test_endpoint "GET" "$API_BASE/oauth/callback?provider=twitter" "" "200" "Twitter OAuth callback"
test_endpoint "GET" "$API_BASE/oauth/callback?provider=linkedin" "" "200" "LinkedIn OAuth callback"

print_section "User Management Tests"

# Extract token from callback response for subsequent tests
if [ -f /tmp/response.json ]; then
    TOKEN=$(cat /tmp/response.json | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$TOKEN" ]; then
        echo -e "${GREEN}Token extracted: ${TOKEN:0:20}...${NC}"
    fi
fi

# Test get user profile (requires authentication)
if [ -n "$TOKEN" ]; then
    echo -e "\n${YELLOW}Testing User Profile (with authentication)...${NC}"
    test_endpoint "GET" "$API_BASE/users/1" "" "200" "Get user profile (authenticated)"
    
    # Test update user
    UPDATE_DATA='{
        "user": {
            "first_name": "OAuth",
            "last_name": "User"
        }
    }'
    test_endpoint "PUT" "$API_BASE/users/1" "$UPDATE_DATA" "200" "Update user profile"
    
    # Test get user profile with OAuth accounts
    test_endpoint "GET" "$API_BASE/users/1/profile" "" "200" "Get user profile with OAuth accounts"
else
    echo -e "${RED}No token available for authenticated tests${NC}"
fi

print_section "Error Handling Tests"

# Test unauthorized access
echo -e "\n${YELLOW}Testing Error Cases...${NC}"
test_endpoint "GET" "$API_BASE/users/1" "" "401" "Unauthorized access to user profile"

# Test invalid OAuth callback
test_endpoint "GET" "$API_BASE/oauth/callback" "" "200" "OAuth callback without provider"

print_section "OAuth Account Management Tests"

# Test user profile to see connected providers
if [ -n "$TOKEN" ]; then
    echo -e "\n${YELLOW}Testing OAuth Account Management...${NC}"
    test_endpoint "GET" "$API_BASE/users/1/profile" "" "200" "Get user profile with OAuth accounts"
fi

print_section "Integration Tests"

# Test multiple OAuth providers for same user
echo -e "\n${YELLOW}Testing Multiple OAuth Providers...${NC}"
test_endpoint "GET" "$API_BASE/oauth/callback?provider=google" "" "200" "First OAuth provider (Google)"
test_endpoint "GET" "$API_BASE/oauth/callback?provider=facebook" "" "200" "Second OAuth provider (Facebook)"

print_section "Test Summary"
echo -e "\n${BLUE}Test Results:${NC}"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}Total Tests: $((TESTS_PASSED + TESTS_FAILED))${NC}"

# Stop the Rails server
echo -e "\n${YELLOW}Stopping OAuth Service server...${NC}"
pkill -f "rails server"

# Cleanup
rm -f /tmp/response.json

echo -e "\n${GREEN}OAuth Service testing completed!${NC}"
