#!/bin/bash

# Quick Test Script for Microservices
# This script quickly tests basic functionality

echo "🧪 Quick Microservices Test"
echo "=========================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
PASSED=0
FAILED=0

test_endpoint() {
    local url=$1
    local description=$2
    
    response=$(curl -s -w "%{http_code}" -o /dev/null "$url")
    status="${response: -3}"
    
    if [ "$status" = "200" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $description"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $description (Status: $status)"
        ((FAILED++))
    fi
}

# Start Auth Service
echo -e "\n${YELLOW}Starting Auth Service...${NC}"
cd auth-service
rails server -p 3000 -d
cd ..

# Start OAuth Service
echo -e "\n${YELLOW}Starting OAuth Service...${NC}"
cd oauth-service
rails server -p 3001 -d
cd ..

# Wait for services to start
echo -e "\n${YELLOW}Waiting for services to start...${NC}"
sleep 10

# Test health endpoints
echo -e "\n${YELLOW}Testing Health Endpoints...${NC}"
test_endpoint "http://localhost:3000/health" "Auth Service Health"
test_endpoint "http://localhost:3001/health" "OAuth Service Health"

# Test basic API endpoints
echo -e "\n${YELLOW}Testing Basic API Endpoints...${NC}"
test_endpoint "http://localhost:3000/api/v1/auth/login" "Auth Service Login Endpoint"
test_endpoint "http://localhost:3001/api/v1/oauth/google" "OAuth Service Google Endpoint"

# Stop services
echo -e "\n${YELLOW}Stopping services...${NC}"
pkill -f "rails server"
sleep 2

# Results
echo -e "\n${YELLOW}Quick Test Results:${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All quick tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  Some tests failed!${NC}"
    exit 1
fi
