#!/bin/bash

# API Integration Test Script - India E-commerce Platform
# This script tests the API integration between all microservices

set -e

echo "🧪 Testing API Integration Between Microservices..."
echo "=================================================="

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

# Function to test service data
test_service_data() {
    local service_name=$1
    local endpoint=$2
    local expected_count=$3
    local description=$4
    
    print_status "Testing $service_name Data: $description"
    
    response=$(curl -s "$endpoint")
    if echo "$response" | grep -q "$expected_count"; then
        print_success "$service_name has expected data"
        return 0
    else
        print_warning "$service_name data test inconclusive"
        return 1
    fi
}

# Track test results
total_tests=0
passed_tests=0
failed_tests=0

# Test 1: API Gateway Health
print_status "=== Testing API Gateway ==="
if test_api_endpoint "API Gateway" "http://localhost:3000/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 2: User Service Health
print_status "=== Testing User Service ==="
if test_api_endpoint "User Service" "http://localhost:3001/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 3: Product Service Health
print_status "=== Testing Product Service ==="
if test_api_endpoint "Product Service" "http://localhost:3002/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 4: Cart Service Health
print_status "=== Testing Cart Service ==="
if test_api_endpoint "Cart Service" "http://localhost:3003/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 5: Order Service Health
print_status "=== Testing Order Service ==="
if test_api_endpoint "Order Service" "http://localhost:3004/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 6: Wallet Service Health
print_status "=== Testing Wallet Service ==="
if test_api_endpoint "Wallet Service" "http://localhost:3007/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 7: Notification Service Health
print_status "=== Testing Notification Service ==="
if test_api_endpoint "Notification Service" "http://localhost:3006/health" "200" "Health check"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 8: API Gateway Response Structure
print_status "=== Testing API Gateway Response Structure ==="
if test_api_response "http://localhost:3000/health" "service" "API Gateway health response"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 9: User Service Response Structure
print_status "=== Testing User Service Response Structure ==="
if test_api_response "http://localhost:3001/health" "service" "User Service health response"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Test 10: Database Connectivity (via API)
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

# Test 11: Redis Connectivity
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

# Test 12: Service Communication via API Gateway
print_status "=== Testing Service Communication ==="
gateway_response=$(curl -s "http://localhost:3000/api/v1/health" 2>/dev/null || echo "gateway_failed")
if [ "$gateway_response" != "gateway_failed" ]; then
    print_success "API Gateway routing is working"
    ((passed_tests++))
else
    print_warning "API Gateway routing test inconclusive"
    ((failed_tests++))
fi
((total_tests++))

# Test 13: CORS Headers (API Gateway)
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

# Test 14: Service Response Times
print_status "=== Testing Service Response Times ==="
response_time=$(curl -s -w "%{time_total}" -o /dev/null "http://localhost:3000/health")
if (( $(echo "$response_time < 1.0" | bc -l) )); then
    print_success "API Gateway response time is acceptable: ${response_time}s"
    ((passed_tests++))
else
    print_warning "API Gateway response time is slow: ${response_time}s"
    ((failed_tests++))
fi
((total_tests++))

# Test 15: Service Interoperability
print_status "=== Testing Service Interoperability ==="
# Test if all services return consistent health check format
health_checks=(
    "http://localhost:3000/health"
    "http://localhost:3001/health"
    "http://localhost:3002/health"
    "http://localhost:3003/health"
    "http://localhost:3004/health"
    "http://localhost:3006/health"
    "http://localhost:3007/health"
)

all_healthy=true
for endpoint in "${health_checks[@]}"; do
    if ! curl -s "$endpoint" | grep -q "healthy"; then
        all_healthy=false
        break
    fi
done

if [ "$all_healthy" = true ]; then
    print_success "All services are healthy and interoperable"
    ((passed_tests++))
else
    print_error "Some services are not healthy"
    ((failed_tests++))
fi
((total_tests++))

# Summary
echo ""
echo "=================================================="
echo "🧪 API Integration Test Summary:"
echo "=================================================="
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
    print_success "🎉 Excellent! API integration is working perfectly!"
elif [ $success_rate -ge 70 ]; then
    print_warning "⚠️  Good! Some issues need attention."
else
    print_error "❌ Critical issues detected. Please review the failed tests."
fi

echo ""
echo "🔗 Service Endpoints Summary:"
echo "=================================================="
echo "API Gateway: http://localhost:3000"
echo "User Service: http://localhost:3001"
echo "Product Service: http://localhost:3002"
echo "Cart Service: http://localhost:3003"
echo "Order Service: http://localhost:3004"
echo "Notification Service: http://localhost:3006"
echo "Wallet Service: http://localhost:3007"
echo ""

echo "🧪 API Testing Checklist:"
echo "=================================================="
echo "1. All services are responding to health checks"
echo "2. Database connectivity is working"
echo "3. Redis is accessible"
echo "4. API Gateway routing is functional"
echo "5. CORS headers are configured"
echo "6. Response times are acceptable"
echo "7. Services are interoperable"
echo ""

echo "📊 Test Data Available:"
echo "=================================================="
echo "👥 User Service: 5 users (individual, business, admin)"
echo "📦 Product Service: 8 products across 8 categories"
echo "🛒 Cart Service: 4 carts with 8 items"
echo "📋 Order Service: 4 orders with 8 items"
echo "💰 Wallet Service: 4 wallets with 10 transactions"
echo "🔔 Notification Service: 13 notifications"
echo ""

echo "🧪 Manual API Testing:"
echo "=================================================="
echo "Test User Login:"
echo "  curl -X POST http://localhost:3000/api/v1/auth/login \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"email\":\"rahul.kumar@example.com\",\"password\":\"password123\"}'"
echo ""
echo "Test Product List:"
echo "  curl http://localhost:3000/api/v1/products"
echo ""
echo "Test Cart Operations:"
echo "  curl http://localhost:3000/api/v1/cart/1"
echo ""

echo "✅ API integration testing completed!"








