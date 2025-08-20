#!/bin/bash

echo "🚀 MICROSERVICES STARTUP SCRIPT"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 0
    else
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    echo -e "${BLUE}Waiting for $service_name to be ready...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready!${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ $service_name failed to start${NC}"
    return 1
}

# Function to start simple API server
start_simple_api() {
    echo -e "\n${YELLOW}🔧 Starting Simple API Server...${NC}"
    
    if check_port 3000; then
        echo -e "${YELLOW}⚠️  Port 3000 is already in use${NC}"
        return 1
    fi
    
    echo "Starting API server on port 3000..."
    nohup ruby simple-rails-api.rb > api-server.log 2>&1 &
    API_PID=$!
    echo $API_PID > /tmp/api-server.pid
    
    wait_for_service "http://localhost:3000/health" "API Server"
    return $?
}

# Function to start infrastructure
start_infrastructure() {
    echo -e "\n${YELLOW}🗄️ Starting Infrastructure...${NC}"
    
    # Start PostgreSQL and Redis
    docker-compose up -d postgres redis
    
    # Wait for PostgreSQL
    echo "Waiting for PostgreSQL..."
    sleep 10
    
    # Test PostgreSQL connection
    if docker exec shopping_cart-postgres-1 psql -U postgres -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
    else
        echo -e "${RED}❌ PostgreSQL failed to start${NC}"
        return 1
    fi
    
    # Test Redis connection
    if docker exec shopping_cart-redis-1 redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Redis is ready${NC}"
    else
        echo -e "${RED}❌ Redis failed to start${NC}"
        return 1
    fi
    
    return 0
}

# Function to start admin dashboard
start_admin_dashboard() {
    echo -e "\n${YELLOW}📊 Starting Admin Dashboard...${NC}"
    
    if check_port 3008; then
        echo -e "${YELLOW}⚠️  Port 3008 is already in use${NC}"
        return 1
    fi
    
    docker-compose up -d admin-dashboard
    
    wait_for_service "http://localhost:3008" "Admin Dashboard"
    return $?
}

# Function to start all Rails microservices
start_rails_microservices() {
    echo -e "\n${YELLOW}🔧 Starting Rails Microservices...${NC}"
    
    # Start all services
    docker-compose up -d
    
    echo "Waiting for services to start..."
    sleep 30
    
    # Check service status
    echo -e "\n${BLUE}Service Status:${NC}"
    docker-compose ps
    
    return 0
}

# Function to show status
show_status() {
    echo -e "\n${YELLOW}📊 SYSTEM STATUS${NC}"
    echo "==============="
    
    # Check infrastructure
    echo -e "\n${BLUE}Infrastructure:${NC}"
    if docker ps | grep -q "postgres"; then
        echo -e "${GREEN}✅ PostgreSQL: Running${NC}"
    else
        echo -e "${RED}❌ PostgreSQL: Not running${NC}"
    fi
    
    if docker ps | grep -q "redis"; then
        echo -e "${GREEN}✅ Redis: Running${NC}"
    else
        echo -e "${RED}❌ Redis: Not running${NC}"
    fi
    
    # Check API server
    echo -e "\n${BLUE}API Server:${NC}"
    if check_port 3000; then
        echo -e "${GREEN}✅ API Server: Running on port 3000${NC}"
    else
        echo -e "${RED}❌ API Server: Not running${NC}"
    fi
    
    # Check admin dashboard
    echo -e "\n${BLUE}Admin Dashboard:${NC}"
    if check_port 3008; then
        echo -e "${GREEN}✅ Admin Dashboard: Running on port 3008${NC}"
    else
        echo -e "${RED}❌ Admin Dashboard: Not running${NC}"
    fi
    
    # Check Rails microservices
    echo -e "\n${BLUE}Rails Microservices:${NC}"
    services=("api-gateway" "user-service" "product-service" "order-service" "cart-service" "notification-service" "wallet-service")
    for service in "${services[@]}"; do
        if docker ps | grep -q "$service"; then
            echo -e "${GREEN}✅ $service: Running${NC}"
        else
            echo -e "${RED}❌ $service: Not running${NC}"
        fi
    done
}

# Function to stop services
stop_services() {
    echo -e "\n${YELLOW}🛑 Stopping Services...${NC}"
    
    # Stop API server if running
    if [ -f /tmp/api-server.pid ]; then
        API_PID=$(cat /tmp/api-server.pid)
        if kill -0 $API_PID 2>/dev/null; then
            echo "Stopping API server (PID: $API_PID)..."
            kill $API_PID
            rm /tmp/api-server.pid
        fi
    fi
    
    # Stop Docker services
    docker-compose down
    
    echo -e "${GREEN}✅ All services stopped${NC}"
}

# Function to show help
show_help() {
    echo -e "\n${BLUE}USAGE: $0 [OPTION]${NC}"
    echo ""
    echo "Options:"
    echo "  simple     - Start simple setup (infrastructure + API server + admin dashboard)"
    echo "  full       - Start full microservices setup (all Rails services)"
    echo "  infra      - Start infrastructure only (PostgreSQL + Redis)"
    echo "  api        - Start simple API server only"
    echo "  dashboard  - Start admin dashboard only"
    echo "  status     - Show status of all services"
    echo "  stop       - Stop all services"
    echo "  test       - Run system tests"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 simple    # Quick start (recommended)"
    echo "  $0 full      # Complete microservices setup"
    echo "  $0 status    # Check what's running"
    echo "  $0 stop      # Stop everything"
}

# Function to run tests
run_tests() {
    echo -e "\n${YELLOW}🧪 Running System Tests...${NC}"
    
    if [ -f "./test-complete-system.sh" ]; then
        ./test-complete-system.sh
    else
        echo -e "${RED}❌ Test script not found${NC}"
    fi
}

# Main execution
case "${1:-simple}" in
    "simple")
        echo -e "${GREEN}🚀 Starting Simple Setup (Recommended)${NC}"
        start_infrastructure
        if [ $? -eq 0 ]; then
            start_simple_api
            if [ $? -eq 0 ]; then
                start_admin_dashboard
                if [ $? -eq 0 ]; then
                    echo -e "\n${GREEN}🎉 Simple setup complete!${NC}"
                    echo -e "${BLUE}Access your admin dashboard: http://localhost:3008${NC}"
                    echo -e "${BLUE}Login with: admin@ecommerce.com / password123${NC}"
                fi
            fi
        fi
        ;;
    
    "full")
        echo -e "${GREEN}🚀 Starting Full Microservices Setup${NC}"
        start_infrastructure
        if [ $? -eq 0 ]; then
            start_rails_microservices
            if [ $? -eq 0 ]; then
                start_admin_dashboard
                if [ $? -eq 0 ]; then
                    echo -e "\n${GREEN}🎉 Full microservices setup complete!${NC}"
                    echo -e "${BLUE}Access your admin dashboard: http://localhost:3008${NC}"
                fi
            fi
        fi
        ;;
    
    "infra")
        echo -e "${GREEN}🗄️ Starting Infrastructure Only${NC}"
        start_infrastructure
        ;;
    
    "api")
        echo -e "${GREEN}🔧 Starting API Server Only${NC}"
        start_simple_api
        ;;
    
    "dashboard")
        echo -e "${GREEN}📊 Starting Admin Dashboard Only${NC}"
        start_admin_dashboard
        ;;
    
    "status")
        show_status
        ;;
    
    "stop")
        stop_services
        ;;
    
    "test")
        run_tests
        ;;
    
    "help"|"-h"|"--help")
        show_help
        ;;
    
    *)
        echo -e "${RED}❌ Unknown option: $1${NC}"
        show_help
        exit 1
        ;;
esac

# Show final status
if [ "$1" != "status" ] && [ "$1" != "stop" ] && [ "$1" != "help" ] && [ "$1" != "test" ]; then
    echo ""
    show_status
fi



