#!/bin/bash

# Rate Limiting & Brute Force Protection Test Script
# Quick testing script using cURL

BASE_URL="http://localhost:3000"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Rate Limiting & Brute Force Protection Test${NC}"
echo "=================================================="

# Function to make HTTP requests
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local headers=$4
    
    if [ "$method" = "POST" ]; then
        curl -s -w "Status: %{http_code}\n" -X POST "$BASE_URL$endpoint" \
             -H "Content-Type: application/json" \
             -d "$data" \
             $headers
    else
        curl -s -w "Status: %{http_code}\n" -X GET "$BASE_URL$endpoint" \
             $headers
    fi
}

# Test 1: Login Rate Limiting
echo -e "\n${YELLOW}🔐 Testing Login Rate Limiting (5 attempts per 20 seconds)${NC}"
echo "----------------------------------------------------"

for i in {1..7}; do
    echo -n "Attempt $i: "
    response=$(make_request "POST" "/users/sign_in" '{"user":{"email":"test@example.com","password":"wrong"}}')
    status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
    
    if [ "$status" = "401" ]; then
        echo -e "${GREEN}✅ 401 (Unauthorized - expected)${NC}"
    elif [ "$status" = "429" ]; then
        echo -e "${RED}🚫 429 (Rate Limited)${NC}"
        break
    else
        echo -e "${RED}❌ $status (Unexpected)${NC}"
    fi
    
    sleep 0.5
done

# Test 2: API Rate Limiting
echo -e "\n${YELLOW}🌐 Testing API Rate Limiting (100 requests per minute)${NC}"
echo "----------------------------------------------------"

success_count=0
for i in {1..105}; do
    response=$(make_request "GET" "/api/v1/users/1")
    status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
    
    if [ "$status" != "429" ]; then
        success_count=$((success_count + 1))
        if [ $((i % 20)) -eq 0 ]; then
            echo "Request $i: ✅ $status"
        fi
    else
        echo "Request $i: 🚫 429 (Rate Limited)"
        break
    fi
    
    sleep 0.1
done

echo "Successfully made $success_count requests before rate limiting"

# Test 3: Attack Pattern Blocking
echo -e "\n${YELLOW}🚨 Testing Attack Pattern Blocking${NC}"
echo "----------------------------------------"

# SQL Injection
echo -n "SQL Injection: "
response=$(make_request "GET" "/api/v1/users?id=1 OR 1=1")
status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
if [ "$status" = "403" ]; then
    echo -e "${GREEN}✅ 403 (Blocked)${NC}"
else
    echo -e "${RED}❌ $status (Not Blocked)${NC}"
fi

# XSS Attack
echo -n "XSS Attack: "
response=$(make_request "GET" "/api/v1/users?name=<script>alert(1)</script>")
status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
if [ "$status" = "403" ]; then
    echo -e "${GREEN}✅ 403 (Blocked)${NC}"
else
    echo -e "${RED}❌ $status (Not Blocked)${NC}"
fi

# Path Traversal
echo -n "Path Traversal: "
response=$(make_request "GET" "/api/v1/files?path=../../etc/passwd")
status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
if [ "$status" = "403" ]; then
    echo -e "${GREEN}✅ 403 (Blocked)${NC}"
else
    echo -e "${RED}❌ $status (Not Blocked)${NC}"
fi

# Test 4: User Agent Blocking
echo -e "\n${YELLOW}🤖 Testing User Agent Blocking${NC}"
echo "--------------------------------"

# Normal Browser
echo -n "Normal Browser: "
response=$(make_request "GET" "/" "" "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'")
status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
if [ "$status" != "403" ]; then
    echo -e "${GREEN}✅ $status (Allowed)${NC}"
else
    echo -e "${RED}❌ $status (Blocked)${NC}"
fi

# Bot User Agent
echo -n "Bot User Agent: "
response=$(make_request "GET" "/" "" "-H 'User-Agent: sqlmap/1.0'")
status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
if [ "$status" = "403" ]; then
    echo -e "${GREEN}✅ 403 (Blocked)${NC}"
else
    echo -e "${RED}❌ $status (Not Blocked)${NC}"
fi

# Test 5: Rate Limit Headers
echo -e "\n${YELLOW}📋 Testing Rate Limit Headers${NC}"
echo "--------------------------------"

# Trigger rate limiting first
for i in {1..105}; do
    make_request "GET" "/api/v1/users/1" > /dev/null 2>&1
done

# Check headers
echo "Checking rate limit headers:"
response=$(curl -s -I "$BASE_URL/api/v1/users/1")
echo "$response" | grep -i "retry-after\|x-ratelimit" || echo "No rate limit headers found"

# Test 6: Registration Rate Limiting
echo -e "\n${YELLOW}📝 Testing Registration Rate Limiting (3 attempts per hour)${NC}"
echo "----------------------------------------------------"

for i in {1..5}; do
    echo -n "Attempt $i: "
    response=$(make_request "POST" "/users" "{\"user\":{\"email\":\"test$i@example.com\",\"password\":\"password123\",\"password_confirmation\":\"password123\"}}")
    status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
    
    if [ "$status" != "429" ]; then
        echo -e "${GREEN}✅ $status${NC}"
    else
        echo -e "${RED}🚫 429 (Rate Limited)${NC}"
        break
    fi
    
    sleep 0.5
done

# Test 7: Password Reset Rate Limiting
echo -e "\n${YELLOW}🔑 Testing Password Reset Rate Limiting (3 attempts per hour)${NC}"
echo "----------------------------------------------------"

for i in {1..5}; do
    echo -n "Attempt $i: "
    response=$(make_request "POST" "/users/password" "{\"user\":{\"email\":\"test$i@example.com\"}}")
    status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
    
    if [ "$status" != "429" ]; then
        echo -e "${GREEN}✅ $status${NC}"
    else
        echo -e "${RED}🚫 429 (Rate Limited)${NC}"
        break
    fi
    
    sleep 0.5
done

echo -e "\n${BLUE}=================================================="
echo -e "🎉 Rate Limiting Tests Completed!${NC}"
echo -e "${BLUE}==================================================${NC}"

echo -e "\n${YELLOW}💡 Tips:${NC}"
echo "• Run 'bundle exec rspec spec/initializers/rack_attack_spec.rb' for automated tests"
echo "• Check 'log/development.log' for rate limiting events"
echo "• Use 'ENABLE_ATTACK_PATTERNS=true' to enable security features in development"
echo "• Monitor production logs for rate limiting metrics"
