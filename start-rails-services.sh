#!/bin/bash

echo "🚀 STARTING RAILS SERVICES LOCALLY"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to start a Rails service
start_rails_service() {
    local service_name=$1
    local port=$2
    local db_name=$3
    
    echo -e "\n${BLUE}Starting $service_name on port $port...${NC}"
    
    cd "services/$service_name"
    
    # Set environment variables
    export DATABASE_URL="postgresql://postgres:password@localhost:5432/${db_name}"
    export RAILS_ENV=development
    export PORT=$port
    
    # Install dependencies if needed
    if [ ! -f "Gemfile.lock" ]; then
        echo "Installing dependencies..."
        bundle install
    fi
    
    # Create database if it doesn't exist
    echo "Setting up database..."
    bundle exec rails db:create 2>/dev/null || echo "Database might already exist"
    bundle exec rails db:migrate 2>/dev/null || echo "Migrations might already be run"
    bundle exec rails db:seed 2>/dev/null || echo "Seed data might already be loaded"
    
    # Start the server in background
    echo "Starting Rails server on port $port..."
    bundle exec rails server -p $port -b 0.0.0.0 &
    
    # Store the process ID
    echo $! > "/tmp/rails_${service_name}.pid"
    
    cd ../..
    
    echo -e "${GREEN}✅ $service_name started on port $port${NC}"
}

# Function to check if PostgreSQL is running
check_postgres() {
    echo -e "\n${BLUE}Checking PostgreSQL...${NC}"
    
    if docker ps | grep -q "postgres"; then
        echo -e "${GREEN}✅ PostgreSQL is running${NC}"
        return 0
    else
        echo -e "${RED}❌ PostgreSQL is not running${NC}"
        echo "Starting PostgreSQL..."
        docker-compose up -d postgres redis
        sleep 5
        return 0
    fi
}

# Function to create databases
create_databases() {
    echo -e "\n${BLUE}Creating databases...${NC}"
    
    databases=(
        "user_service_development"
        "product_service_development"
        "order_service_development"
        "cart_service_development"
        "wallet_service_development"
        "notification_service_development"
        "api_gateway_development"
    )
    
    for db in "${databases[@]}"; do
        echo "Creating database: $db"
        docker exec shopping_cart-postgres-1 psql -U postgres -d postgres -c "CREATE DATABASE $db;" 2>/dev/null || echo "Database $db might already exist"
    done
    
    echo -e "${GREEN}✅ Databases created${NC}"
}

# Function to stop all Rails services
stop_rails_services() {
    echo -e "\n${BLUE}Stopping Rails services...${NC}"
    
    for pid_file in /tmp/rails_*.pid; do
        if [ -f "$pid_file" ]; then
            pid=$(cat "$pid_file")
            service_name=$(basename "$pid_file" .pid | sed 's/rails_//')
            echo "Stopping $service_name (PID: $pid)"
            kill $pid 2>/dev/null || echo "Process $pid not found"
            rm "$pid_file"
        fi
    done
    
    echo -e "${GREEN}✅ Rails services stopped${NC}"
}

# Function to show status
show_status() {
    echo -e "\n${YELLOW}📊 SERVICE STATUS${NC}"
    echo "=================="
    
    services=(
        "user-service:3001"
        "product-service:3002"
        "order-service:3003"
        "cart-service:3004"
        "wallet-service:3007"
        "notification-service:3006"
        "api-gateway:3000"
    )
    
    for service in "${services[@]}"; do
        service_name=$(echo $service | cut -d: -f1)
        port=$(echo $service | cut -d: -f2)
        
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name (port $port) - Running${NC}"
        else
            echo -e "${RED}❌ $service_name (port $port) - Not responding${NC}"
        fi
    done
    
    echo -e "\n${BLUE}Admin Dashboard: http://localhost:3008${NC}"
    echo -e "${BLUE}API Gateway: http://localhost:3000${NC}"
}

# Main execution
case "${1:-start}" in
    "start")
        # Check if PostgreSQL is running
        check_postgres
        
        # Create databases
        create_databases
        
        # Start Rails services
        start_rails_service "user-service" 3001 "user_service_development"
        start_rails_service "product-service" 3002 "product_service_development"
        start_rails_service "order-service" 3003 "order_service_development"
        start_rails_service "cart-service" 3004 "cart_service_development"
        start_rails_service "wallet-service" 3007 "wallet_service_development"
        start_rails_service "notification-service" 3006 "notification_service_development"
        start_rails_service "api-gateway" 3000 "api_gateway_development"
        
        # Wait a moment for services to start
        sleep 5
        
        # Show status
        show_status
        
        echo -e "\n${GREEN}🎉 Rails services started!${NC}"
        echo -e "${BLUE}Access your admin dashboard: http://localhost:3008${NC}"
        echo -e "${BLUE}Login with: admin@ecommerce.com / password123${NC}"
        ;;
    
    "stop")
        stop_rails_services
        ;;
    
    "status")
        show_status
        ;;
    
    "restart")
        stop_rails_services
        sleep 2
        $0 start
        ;;
    
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        echo "  start   - Start all Rails services"
        echo "  stop    - Stop all Rails services"
        echo "  status  - Show service status"
        echo "  restart - Restart all services"
        exit 1
        ;;
esac



