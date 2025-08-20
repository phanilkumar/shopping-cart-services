#!/bin/bash

echo "🚀 Starting Microservices and Admin Dashboard"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo -e "${RED}❌ Port $1 is already in use${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Port $1 is available${NC}"
        return 0
    fi
}

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

# Check if required tools are installed
echo -e "\n${BLUE}🔍 Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker not found, will use Rails directly${NC}"
    DOCKER_AVAILABLE=false
else
    echo -e "${GREEN}✅ Docker found${NC}"
    DOCKER_AVAILABLE=true
fi

if ! command -v bundle &> /dev/null; then
    echo -e "${RED}❌ Bundler not found. Please install Ruby and Bundler${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Bundler found${NC}"
fi

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js 16+${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Node.js found${NC}"
fi

# Check ports
echo -e "\n${BLUE}🔍 Checking port availability...${NC}"
check_port 3001 || exit 1
check_port 3002 || exit 1
check_port 3003 || exit 1
check_port 3000 || exit 1

# Start microservices
echo -e "\n${BLUE}🚀 Starting Microservices...${NC}"

# Start Auth Service (Port 3001)
start_service "auth-service" "services/auth-service" 3001

# Start OAuth Service (Port 3002)
start_service "oauth-service" "services/oauth-service" 3002

# Start User Service (Port 3003)
start_service "user-service" "services/user-service" 3003

# Wait for services to be ready
echo -e "\n${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 5

# Start Admin Dashboard
echo -e "\n${BLUE}📊 Starting Admin Dashboard...${NC}"
cd admin-dashboard

if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing admin dashboard dependencies...${NC}"
    npm install
fi

echo -e "${GREEN}🌐 Starting admin dashboard on http://localhost:3000${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"

# Start admin dashboard in background
npm start &
ADMIN_PID=$!

cd - > /dev/null

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Stopping all services...${NC}"
    
    # Stop admin dashboard
    if [ ! -z "$ADMIN_PID" ]; then
        kill $ADMIN_PID 2>/dev/null
    fi
    
    # Stop Rails servers
    pkill -f "rails server" 2>/dev/null
    
    # Stop Docker containers
    if [ "$DOCKER_AVAILABLE" = true ]; then
        docker stop auth-service oauth-service user-service 2>/dev/null
        docker rm auth-service oauth-service user-service 2>/dev/null
    fi
    
    echo -e "${GREEN}✅ All services stopped${NC}"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Wait for admin dashboard
wait $ADMIN_PID
