#!/bin/bash

# Seed All Services Script - India E-commerce Platform
# This script seeds all microservices with comprehensive test data

set -e

echo "🌱 Starting to seed all microservices..."
echo "========================================"

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

# Function to seed a service
seed_service() {
    local service_name=$1
    local service_port=$2
    
    print_status "Seeding $service_name..."
    
    # Check if service is running
    if ! curl -s "http://localhost:$service_port/health" > /dev/null; then
        print_warning "$service_name is not running. Starting it..."
        docker-compose -f /Users/phanindra/Documents/shopping_cart/docker-compose.yml up -d $service_name
        sleep 5
    fi
    
    # Run seed command
    if docker-compose -f /Users/phanindra/Documents/shopping_cart/docker-compose.yml exec -T $service_name sh -c "cd /rails && bin/rails db:seed"; then
        print_success "$service_name seeded successfully!"
    else
        print_error "Failed to seed $service_name"
        return 1
    fi
}

# Start required services
print_status "Starting required services..."
docker-compose -f /Users/phanindra/Documents/shopping_cart/docker-compose.yml up -d postgres redis

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Seed services in order (dependencies first)
services=(
    "user-service:3001"
    "product-service:3002"
    "cart-service:3003"
    "order-service:3004"
    "wallet-service:3007"
    "notification-service:3006"
)

# Track success/failure
success_count=0
failure_count=0

for service in "${services[@]}"; do
    service_name=$(echo $service | cut -d: -f1)
    service_port=$(echo $service | cut -d: -f2)
    
    if seed_service $service_name $service_port; then
        ((success_count++))
    else
        ((failure_count++))
    fi
    
    echo ""
done

# Summary
echo "========================================"
echo "🌱 Seeding Summary:"
echo "========================================"
print_success "Successfully seeded: $success_count services"
if [ $failure_count -gt 0 ]; then
    print_error "Failed to seed: $failure_count services"
else
    print_success "All services seeded successfully! 🎉"
fi

echo ""
echo "📊 Test Data Overview:"
echo "========================================"
echo "👥 User Service: 5 users (individual, business, admin)"
echo "📦 Product Service: 8 products across 8 categories"
echo "🛒 Cart Service: 4 carts with 8 items"
echo "📋 Order Service: 4 orders with 8 items"
echo "💰 Wallet Service: 4 wallets with 10 transactions"
echo "🔔 Notification Service: 13 notifications"
echo ""
echo "🧪 Test Credentials:"
echo "========================================"
echo "Email: rahul.kumar@example.com"
echo "Phone: +919876543210"
echo "Email: priya.sharma@example.com"
echo "Phone: +919876543211"
echo "Email: amit.patel@business.com (Business User)"
echo "Phone: +919876543212"
echo ""
echo "🔗 Service Endpoints:"
echo "========================================"
echo "API Gateway: http://localhost:3000"
echo "User Service: http://localhost:3001"
echo "Product Service: http://localhost:3002"
echo "Cart Service: http://localhost:3003"
echo "Order Service: http://localhost:3004"
echo "Payment Service: http://localhost:3005"
echo "Notification Service: http://localhost:3006"
echo "Wallet Service: http://localhost:3007"
echo ""
echo "✅ Ready for testing! Run 'docker-compose logs -f' to monitor services."




