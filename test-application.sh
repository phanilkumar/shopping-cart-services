#!/bin/bash

echo "🚀 Testing E-commerce Application Stack"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test service
test_service() {
    local service_name=$1
    local url=$2
    local description=$3
    
    echo -e "\n${BLUE}Testing $service_name...${NC}"
    echo "Description: $description"
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service_name is running and accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name is not accessible${NC}"
        return 1
    fi
}

# Function to test database
test_database() {
    echo -e "\n${BLUE}Testing Database Connectivity...${NC}"
    
    if docker exec shopping_cart-postgres-1 psql -U postgres -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL is running and accessible${NC}"
    else
        echo -e "${RED}❌ PostgreSQL is not accessible${NC}"
    fi
}

# Function to test Redis
test_redis() {
    echo -e "\n${BLUE}Testing Redis Connectivity...${NC}"
    
    if docker exec shopping_cart-redis-1 redis-cli ping | grep -q "PONG"; then
        echo -e "${GREEN}✅ Redis is running and accessible${NC}"
    else
        echo -e "${RED}❌ Redis is not accessible${NC}"
    fi
}

# Function to check container status
check_container_status() {
    local service_name=$1
    local container_name="shopping_cart-${service_name}-1"
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name"; then
        local status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container_name" | awk '{print $2}')
        echo -e "${GREEN}✅ $service_name container is running ($status)${NC}"
    else
        echo -e "${RED}❌ $service_name container is not running${NC}"
    fi
}

echo -e "\n${YELLOW}📊 Container Status Check${NC}"
echo "================================"

# Check all containers
check_container_status "postgres"
check_container_status "redis"
check_container_status "admin-dashboard"

echo -e "\n${YELLOW}🔗 Service Connectivity Test${NC}"
echo "=================================="

# Test services
test_service "Admin Dashboard" "http://localhost:3008" "React Admin Dashboard"
test_service "PostgreSQL" "http://localhost:5432" "Database (port check)"
test_service "Redis" "http://localhost:6379" "Cache (port check)"

echo -e "\n${YELLOW}🗄️ Database Tests${NC}"
echo "=================="

test_database
test_redis

echo -e "\n${YELLOW}📋 Application Summary${NC}"
echo "========================"

echo -e "${BLUE}Available Services:${NC}"
echo "• Admin Dashboard: http://localhost:3008"
echo "• PostgreSQL: localhost:5432"
echo "• Redis: localhost:6379"

echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. Open http://localhost:3008 in your browser"
echo "2. Use the admin dashboard to manage your e-commerce platform"
echo "3. The dashboard includes:"
echo "   - User management"
echo "   - Product management"
echo "   - Order management"
echo "   - Cart management"
echo "   - Wallet management"
echo "   - Notification management"
echo "   - Analytics and reports"

echo -e "\n${GREEN}🎉 Application testing completed!${NC}"

