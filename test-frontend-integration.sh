#!/bin/bash

# Frontend Integration Test Script - India E-commerce Platform
# This script tests the frontend and its API alignment with all microservices

set -e

echo "🧪 Testing Frontend and API Integration..."
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to test API endpoint
test_api_endpoint() {
    local service_name=$1
    local endpoint=$2
    local expected_status=$3
    local description=$4
    
    print_status "Testing $service_name: $description"
    
    if curl -s -o /dev/null -w "%{http_code}" "$endpoint" | grep -q "$expected_status"; then
        print_success "$service_name endpoint working correctly"
        return 0
    else
        print_error "$service_name endpoint failed"
        return 1
    fi
}

# Function to test frontend accessibility
test_frontend() {
    local frontend_url=$1
    local description=$2
    
    print_status "Testing Frontend: $description"
    
    if curl -s -o /dev/null -w "%{http_code}" "$frontend_url" | grep -q "200"; then
        print_success "Frontend is accessible"
        return 0
    else
        print_error "Frontend is not accessible"
        return 1
    fi
}

# Function to test API response structure
test_api_response() {
    local endpoint=$1
    local expected_field=$2
    local description=$3
    
    print_status "Testing API Response: $description"
    
    response=$(curl -s "$endpoint")
    if echo "$response" | grep -q "$expected_field"; then
        print_success "API response structure is correct"
        return 0
    else
        print_error "API response structure is incorrect"
        return 1
    fi
}

# Track test results
total_tests=0
passed_tests=0
failed_tests=0

# Test 1: Frontend Accessibility
print_status "=== Testing Frontend Accessibility ==="
if test_frontend "http://localhost:3005" "Main frontend page"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 2: API Gateway Health
print_status "=== Testing API Gateway ==="
if test_api_endpoint "API Gateway" "http://localhost:3000/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 3: User Service Health
print_status "=== Testing User Service ==="
if test_api_endpoint "User Service" "http://localhost:3001/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 4: Product Service Health
print_status "=== Testing Product Service ==="
if test_api_endpoint "Product Service" "http://localhost:3002/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 5: Cart Service Health
print_status "=== Testing Cart Service ==="
if test_api_endpoint "Cart Service" "http://localhost:3003/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 6: Order Service Health
print_status "=== Testing Order Service ==="
if test_api_endpoint "Order Service" "http://localhost:3004/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 7: Wallet Service Health
print_status "=== Testing Wallet Service ==="
if test_api_endpoint "Wallet Service" "http://localhost:3007/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 8: Notification Service Health
print_status "=== Testing Notification Service ==="
if test_api_endpoint "Notification Service" "http://localhost:3006/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 9: API Gateway Response Structure
print_status "=== Testing API Gateway Response Structure ==="
if test_api_response "http://localhost:3000/health" "service" "API Gateway health response"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 10: User Service Response Structure
print_status "=== Testing User Service Response Structure ==="
if test_api_response "http://localhost:3001/health" "service" "User Service health response"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 11: Frontend API Configuration
print_status "=== Testing Frontend API Configuration ==="
frontend_config=$(curl -s "http://localhost:3005" | grep -o "REACT_APP_API_URL" || true)
if [ -n "$frontend_config" ]; then
    print_success "Frontend has API configuration"
    ((passed_tests++))
else
    print_warning "Frontend API configuration not found in HTML"
    ((failed_tests++))
fi
((total_tests++))

# Test 12: CORS Headers (API Gateway)
print_status "=== Testing CORS Headers ==="
cors_headers=$(curl -s -I "http://localhost:3000/health" | grep -i "access-control" || true)
if [ -n "$cors_headers" ]; then
    print_success "CORS headers are configured"
    ((passed_tests++))
else
    print_warning "CORS headers not found"
    ((failed_tests++))
fi
((total_tests++))

# Test 13: Database Connectivity (via API)
print_status "=== Testing Database Connectivity ==="
db_response=$(curl -s "http://localhost:3001/health" | grep -o "healthy" || true)
if [ -n "$db_response" ]; then
    print_success "Database connectivity is working"
    ((passed_tests++))
else
    print_error "Database connectivity failed"
    ((failed_tests++))
fi
((total_tests++))

# Test 14: Redis Connectivity
print_status "=== Testing Redis Connectivity ==="
redis_response=$(curl -s "http://localhost:6379" 2>/dev/null || echo "connection_failed")
if [ "$redis_response" != "connection_failed" ]; then
    print_success "Redis is accessible"
    ((passed_tests++))
else
    print_warning "Redis connectivity test inconclusive"
    ((failed_tests++))
fi
((total_tests++))

# Test 15: Service Communication
print_status "=== Testing Service Communication ==="
# Test if services can communicate through API Gateway
gateway_response=$(curl -s "http://localhost:3000/api/v1/health" 2>/dev/null || echo "gateway_failed")
if [ "$gateway_response" != "gateway_failed" ]; then
    print_success "API Gateway routing is working"
    ((passed_tests++))
else
    print_warning "API Gateway routing test inconclusive"
    ((failed_tests++))
fi
((total_tests++))

# Summary
echo ""
echo "=========================================="
echo "🧪 Integration Test Summary:"
echo "=========================================="
print_success "Passed: $passed_tests tests"
if [ $failed_tests -gt 0 ]; then
    print_error "Failed: $failed_tests tests"
else
    print_success "Failed: $failed_tests tests"
fi
print_status "Total: $total_tests tests"
echo ""

# Calculate success rate
success_rate=$((passed_tests * 100 / total_tests))
echo "📊 Success Rate: $success_rate%"

if [ $success_rate -ge 90 ]; then
    print_success "🎉 Excellent! Frontend and API integration is working well!"
elif [ $success_rate -ge 70 ]; then
    print_warning "⚠️  Good! Some issues need attention."
else
    print_error "❌ Critical issues detected. Please review the failed tests."
fi

echo ""
echo "🔗 Service Endpoints Summary:"
echo "=========================================="
echo "Frontend: http://localhost:3005"
echo "API Gateway: http://localhost:3000"
echo "User Service: http://localhost:3001"
echo "Product Service: http://localhost:3002"
echo "Cart Service: http://localhost:3003"
echo "Order Service: http://localhost:3004"
echo "Notification Service: http://localhost:3006"
echo "Wallet Service: http://localhost:3007"
echo ""

echo "🧪 Manual Testing Checklist:"
echo "=========================================="
echo "1. Open http://localhost:3005 in browser"
echo "2. Test login with: rahul.kumar@example.com"
echo "3. Test phone login with: +919876543210"
echo "4. Browse products and add to cart"
echo "5. Test checkout process"
echo "6. Verify notifications"
echo "7. Test wallet functionality"
echo ""

echo "✅ Integration testing completed!"




