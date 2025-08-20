#!/bin/bash

echo "🔍 Checking Services Status"
echo "=========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check service status
check_service() {
    local service_name=$1
    local port=$2
    local url=$3
    
    echo -n "Checking $service_name (Port $port): "
    
    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ ONLINE${NC}"
        return 0
    else
        echo -e "${RED}❌ OFFLINE${NC}"
        return 1
    fi
}

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 0
    else
        return 1
    fi
}

echo -e "\n${BLUE}📊 Service Status:${NC}"

# Check microservices
auth_online=false
oauth_online=false
user_online=false
admin_online=false

# Check Auth Service
if check_service "Auth Service" "3001" "http://localhost:3001/health"; then
    auth_online=true
fi

# Check OAuth Service
if check_service "OAuth Service" "3002" "http://localhost:3002/health"; then
    oauth_online=true
fi

# Check User Service
if check_service "User Service" "3003" "http://localhost:3003/health"; then
    user_online=true
fi

# Check Admin Dashboard
if check_service "Admin Dashboard" "3000" "http://localhost:3000"; then
    admin_online=true
fi

echo -e "\n${BLUE}🔌 Port Status:${NC}"

# Check ports
echo -n "Port 3001 (Auth): "
if check_port 3001; then
    echo -e "${GREEN}✅ IN USE${NC}"
else
    echo -e "${RED}❌ AVAILABLE${NC}"
fi

echo -n "Port 3002 (OAuth): "
if check_port 3002; then
    echo -e "${GREEN}✅ IN USE${NC}"
else
    echo -e "${RED}❌ AVAILABLE${NC}"
fi

echo -n "Port 3003 (User): "
if check_port 3003; then
    echo -e "${GREEN}✅ IN USE${NC}"
else
    echo -e "${RED}❌ AVAILABLE${NC}"
fi

echo -n "Port 3000 (Admin): "
if check_port 3000; then
    echo -e "${GREEN}✅ IN USE${NC}"
else
    echo -e "${RED}❌ AVAILABLE${NC}"
fi

echo -e "\n${BLUE}📈 Summary:${NC}"

online_count=0
if [ "$auth_online" = true ]; then ((online_count++)); fi
if [ "$oauth_online" = true ]; then ((online_count++)); fi
if [ "$user_online" = true ]; then ((online_count++)); fi

echo -e "Microservices: $online_count/3 online"
echo -e "Admin Dashboard: $([ "$admin_online" = true ] && echo "✅ Online" || echo "❌ Offline")"

echo -e "\n${BLUE}🌐 Access URLs:${NC}"
echo -e "Admin Dashboard: http://localhost:3000"
echo -e "Auth Service: http://localhost:3001"
echo -e "OAuth Service: http://localhost:3002"
echo -e "User Service: http://localhost:3003"

if [ $online_count -eq 3 ] && [ "$admin_online" = true ]; then
    echo -e "\n${GREEN}🎉 All services are running!${NC}"
elif [ $online_count -eq 3 ]; then
    echo -e "\n${YELLOW}⚠️  All microservices are running, but admin dashboard is offline${NC}"
    echo -e "Start admin dashboard with: cd admin-dashboard && npm start"
else
    echo -e "\n${RED}❌ Some services are offline${NC}"
    echo -e "Start all services with: ./start-all-services.sh"
fi
