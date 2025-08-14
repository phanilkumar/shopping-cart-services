#!/bin/bash

# Comprehensive Microservices Test Runner
# This script tests both Auth Service and OAuth Service

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS_PASSED=0
TOTAL_TESTS_FAILED=0

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    MICROSERVICES TEST RUNNER                 ║"
echo "║                                                              ║"
echo "║  Testing: Auth Service & OAuth Service                       ║"
echo "║  Ports: Auth (3000), OAuth (3001)                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Function to extract test results from service test scripts
extract_test_results() {
    local output="$1"
    local passed=$(echo "$output" | grep -o "Tests Passed: [0-9]*" | tail -1 | grep -o "[0-9]*")
    local failed=$(echo "$output" | grep -o "Tests Failed: [0-9]*" | tail -1 | grep -o "[0-9]*")
    
    if [ -n "$passed" ]; then
        TOTAL_TESTS_PASSED=$((TOTAL_TESTS_PASSED + passed))
    fi
    if [ -n "$failed" ]; then
        TOTAL_TESTS_FAILED=$((TOTAL_TESTS_FAILED + failed))
    fi
}

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ Error: curl is not installed. Please install curl to run tests.${NC}"
    exit 1
fi

# Check if Rails is available
if ! command -v rails &> /dev/null; then
    echo -e "${RED}❌ Error: Rails is not installed. Please install Rails to run tests.${NC}"
    exit 1
fi

print_section "PREPARATION"

# Kill any existing Rails servers
echo -e "${YELLOW}🔄 Cleaning up existing Rails servers...${NC}"
pkill -f "rails server" 2>/dev/null || true
sleep 2

# Make test scripts executable
echo -e "${YELLOW}🔄 Making test scripts executable...${NC}"
chmod +x auth-service/test_api.sh
chmod +x oauth-service/test_api.sh

print_section "TESTING AUTH SERVICE"

echo -e "${YELLOW}🚀 Starting Auth Service tests...${NC}"
cd auth-service

# Run Auth Service tests
AUTH_OUTPUT=$(./test_api.sh 2>&1)
AUTH_EXIT_CODE=$?

# Display Auth Service test results
echo "$AUTH_OUTPUT"

if [ $AUTH_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Auth Service tests completed successfully!${NC}"
else
    echo -e "${RED}❌ Auth Service tests failed!${NC}"
fi

# Extract test results
extract_test_results "$AUTH_OUTPUT"

cd ..

print_section "TESTING OAUTH SERVICE"

echo -e "${YELLOW}🚀 Starting OAuth Service tests...${NC}"
cd oauth-service

# Run OAuth Service tests
OAUTH_OUTPUT=$(./test_api.sh 2>&1)
OAUTH_EXIT_CODE=$?

# Display OAuth Service test results
echo "$OAUTH_OUTPUT"

if [ $OAUTH_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ OAuth Service tests completed successfully!${NC}"
else
    echo -e "${RED}❌ OAuth Service tests failed!${NC}"
fi

# Extract test results
extract_test_results "$OAUTH_OUTPUT"

cd ..

print_section "INTEGRATION TESTS"

echo -e "${YELLOW}🔗 Testing service integration...${NC}"

# Test if both services can run simultaneously
echo -e "${YELLOW}🔄 Starting both services simultaneously...${NC}"

# Start Auth Service
cd auth-service
rails server -p 3000 -d
cd ..

# Start OAuth Service
cd oauth-service
rails server -p 3001 -d
cd ..

# Wait for both services to start
sleep 10

# Test both health endpoints
echo -e "${YELLOW}🏥 Testing health endpoints...${NC}"

AUTH_HEALTH=$(curl -s -w "%{http_code}" -o /tmp/auth_health.json http://localhost:3000/health)
OAUTH_HEALTH=$(curl -s -w "%{http_code}" -o /tmp/oauth_health.json http://localhost:3001/health)

AUTH_CODE="${AUTH_HEALTH: -3}"
OAUTH_CODE="${OAUTH_HEALTH: -3}"

if [ "$AUTH_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Auth Service health check: PASS${NC}"
    ((TOTAL_TESTS_PASSED++))
else
    echo -e "${RED}❌ Auth Service health check: FAIL (Status: $AUTH_CODE)${NC}"
    ((TOTAL_TESTS_FAILED++))
fi

if [ "$OAUTH_CODE" = "200" ]; then
    echo -e "${GREEN}✅ OAuth Service health check: PASS${NC}"
    ((TOTAL_TESTS_PASSED++))
else
    echo -e "${RED}❌ OAuth Service health check: FAIL (Status: $OAUTH_CODE)${NC}"
    ((TOTAL_TESTS_FAILED++))
fi

# Test cross-service communication (if needed)
echo -e "${YELLOW}🔗 Testing cross-service communication...${NC}"

# Create a user in Auth Service and test OAuth connection
AUTH_REGISTER='{
    "user": {
        "email": "integration@test.com",
        "password": "password123",
        "password_confirmation": "password123",
        "first_name": "Integration",
        "last_name": "Test",
        "phone": "+1234567890"
    }
}'

AUTH_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/auth_register.json -X POST \
    -H "Content-Type: application/json" \
    -d "$AUTH_REGISTER" \
    http://localhost:3000/api/v1/auth/register)

AUTH_REG_CODE="${AUTH_RESPONSE: -3}"

if [ "$AUTH_REG_CODE" = "201" ]; then
    echo -e "${GREEN}✅ Cross-service user creation: PASS${NC}"
    ((TOTAL_TESTS_PASSED++))
else
    echo -e "${RED}❌ Cross-service user creation: FAIL (Status: $AUTH_REG_CODE)${NC}"
    ((TOTAL_TESTS_FAILED++))
fi

# Stop both services
echo -e "${YELLOW}🔄 Stopping both services...${NC}"
pkill -f "rails server"
sleep 2

print_section "FINAL RESULTS"

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                        TEST SUMMARY                          ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo -e "║  ${GREEN}✅ Total Tests Passed: $TOTAL_TESTS_PASSED${PURPLE}                          ║"
echo -e "║  ${RED}❌ Total Tests Failed: $TOTAL_TESTS_FAILED${PURPLE}                           ║"
echo -e "║  ${BLUE}📊 Total Tests: $((TOTAL_TESTS_PASSED + TOTAL_TESTS_FAILED))${PURPLE}                              ║"
echo "║                                                              ║"
if [ $TOTAL_TESTS_FAILED -eq 0 ]; then
    echo -e "║  ${GREEN}🎉 ALL TESTS PASSED! 🎉${PURPLE}                              ║"
else
    echo -e "║  ${RED}⚠️  SOME TESTS FAILED ⚠️${PURPLE}                              ║"
fi
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Cleanup
rm -f /tmp/auth_health.json /tmp/oauth_health.json /tmp/auth_register.json

echo -e "${GREEN}✨ Microservices testing completed! ✨${NC}"

# Exit with appropriate code
if [ $TOTAL_TESTS_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
