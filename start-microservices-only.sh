#!/bin/bash

echo "🚀 Starting Microservices Only"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to start a service
start_service() {
    local service_name=$1
    local service_dir=$2
    local port=$3
    
    echo -e "\n${BLUE}🔧 Starting $service_name on port $port...${NC}"
    
    if [ ! -d "$service_dir" ]; then
        echo -e "${RED}❌ Service directory $service_dir not found${NC}"
        return 1
    fi
    
    cd "$service_dir"
    
    # Check if Dockerfile exists and use Docker, otherwise use Rails
    if [ -f "Dockerfile" ]; then
        echo -e "${YELLOW}🐳 Using Docker for $service_name${NC}"
        docker build -t $service_name .
        docker run -d --name $service_name -p $port:$port $service_name
    else
        echo -e "${YELLOW}💎 Using Rails for $service_name${NC}"
        if [ ! -d "vendor" ]; then
            echo -e "${YELLOW}📦 Installing dependencies for $service_name...${NC}"
            bundle install
        fi
        
        # Start Rails server in background
        bundle exec rails server -p $port -d
    fi
    
    cd - > /dev/null
    
    # Wait a moment for service to start
    sleep 3
    
    # Check if service is responding
    if curl -s http://localhost:$port/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service_name is running on http://localhost:$port${NC}"
    else
        echo -e "${YELLOW}⚠️  $service_name started but health check failed${NC}"
    fi
}

# Check prerequisites
echo -e "\n${BLUE}🔍 Checking prerequisites...${NC}"

if ! command -v bundle &> /dev/null; then
    echo -e "${RED}❌ Bundler not found. Please install Ruby and Bundler${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Bundler found${NC}"
fi

# Start microservices
echo -e "\n${BLUE}🚀 Starting Microservices...${NC}"

# Start Auth Service (Port 3001)
start_service "auth-service" "services/auth-service" 3001

# Start OAuth Service (Port 3002)
start_service "oauth-service" "services/oauth-service" 3002

# Start User Service (Port 3003)
start_service "user-service" "services/user-service" 3003

echo -e "\n${GREEN}✅ All microservices started!${NC}"
echo -e "${BLUE}📊 You can now start the admin dashboard with: ./admin-dashboard/start.sh${NC}"
echo -e "${BLUE}🌐 Or access services directly:${NC}"
echo -e "   - Auth Service: http://localhost:3001"
echo -e "   - OAuth Service: http://localhost:3002"
echo -e "   - User Service: http://localhost:3003"
