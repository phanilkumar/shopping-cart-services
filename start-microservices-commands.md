# 🚀 Microservices Startup Commands

## 📋 **Quick Start Options**

### **Option 1: Simple API Server (Recommended - Fast & Reliable)**
```bash
# Start the simple API server (single command)
ruby simple-rails-api.rb
```

### **Option 2: Full Rails Microservices (Complete Setup)**
```bash
# Start all Rails microservices with Docker
docker-compose up -d
```

---

## 🔧 **Detailed Commands by Service**

### **1. Infrastructure Services (Required for all options)**

#### **Start PostgreSQL & Redis**
```bash
# Start database and cache
docker-compose up -d postgres redis

# Check status
docker ps | grep -E "(postgres|redis)"

# Check logs
docker logs shopping_cart-postgres-1
docker logs shopping_cart-redis-1
```

#### **Verify Database Connection**
```bash
# Test PostgreSQL connection
docker exec shopping_cart-postgres-1 psql -U postgres -c "SELECT version();"

# Test Redis connection
docker exec shopping_cart-redis-1 redis-cli ping
```

---

### **2. Simple API Server (Option 1 - Recommended)**

#### **Install Dependencies**
```bash
# Install Ruby gems
bundle install

# Verify installation
bundle list | grep sinatra
```

#### **Start API Server**
```bash
# Start the server
ruby simple-rails-api.rb

# Alternative: Start in background
nohup ruby simple-rails-api.rb > api-server.log 2>&1 &

# Check if running
curl http://localhost:3000/health
```

#### **Test API Server**
```bash
# Test health endpoint
curl http://localhost:3000/health

# Test login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@ecommerce.com","password":"password123"}'

# Test admin dashboard data
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@ecommerce.com","password":"password123"}' | \
  grep -o '"token":"[^"]*"' | cut -d'"' -f4)

curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/v1/admin/dashboard
```

---

### **3. Rails Microservices (Option 2 - Complete Setup)**

#### **Update Rails Versions (Already Done)**
```bash
# Verify Rails versions are updated
grep -r "rails.*7.1" services/*/Gemfile

# Expected output:
# services/user-service/Gemfile:gem "rails", "~> 7.1.4"
# services/product-service/Gemfile:gem "rails", "~> 7.1.4"
# services/order-service/Gemfile:gem "rails", "~> 7.1.4"
# services/cart-service/Gemfile:gem "rails", "~> 7.1.4"
# services/notification-service/Gemfile:gem "rails", "~> 7.1.4"
# services/wallet-service/Gemfile:gem "rails", "~> 7.1.4"
# services/api-gateway/Gemfile:gem "rails", "~> 7.1.4"
```

#### **Start All Microservices**
```bash
# Start all services
docker-compose up -d

# Check all containers
docker-compose ps

# View logs for all services
docker-compose logs -f
```

#### **Start Individual Services**
```bash
# Start API Gateway
docker-compose up -d api-gateway

# Start User Service
docker-compose up -d user-service

# Start Product Service
docker-compose up -d product-service

# Start Order Service
docker-compose up -d order-service

# Start Cart Service
docker-compose up -d cart-service

# Start Notification Service
docker-compose up -d notification-service

# Start Wallet Service
docker-compose up -d wallet-service
```

#### **Setup Databases for Rails Services**
```bash
# Create databases for all services
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE user_service_development;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE product_service_development;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE order_service_development;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE cart_service_development;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE wallet_service_development;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE notification_service_development;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE api_gateway_development;"

# Run migrations and seeds (if containers are working)
docker-compose exec api-gateway rails db:migrate db:seed
docker-compose exec user-service rails db:migrate db:seed
docker-compose exec product-service rails db:migrate db:seed
docker-compose exec order-service rails db:migrate db:seed
docker-compose exec cart-service rails db:migrate db:seed
docker-compose exec wallet-service rails db:migrate db:seed
docker-compose exec notification-service rails db:migrate db:seed
```

---

### **4. Admin Dashboard (Frontend)**

#### **Start Admin Dashboard**
```bash
# Start the React admin dashboard
docker-compose up -d admin-dashboard

# Check status
docker ps | grep admin-dashboard

# View logs
docker logs shopping_cart-admin-dashboard-1
```

#### **Test Admin Dashboard**
```bash
# Test if dashboard is accessible
curl -I http://localhost:3008

# Check if React app is loading
curl http://localhost:3008 | grep "E-commerce Admin Dashboard"
```

---

### **5. Complete System Startup**

#### **Option A: Simple Setup (Recommended)**
```bash
# 1. Start infrastructure
docker-compose up -d postgres redis

# 2. Start API server (in new terminal)
ruby simple-rails-api.rb

# 3. Start admin dashboard
docker-compose up -d admin-dashboard

# 4. Test everything
./test-complete-system.sh
```

#### **Option B: Full Microservices Setup**
```bash
# 1. Start everything
docker-compose up -d

# 2. Wait for services to start
sleep 30

# 3. Check all services
docker-compose ps

# 4. Test the system
./test-complete-system.sh
```

---

### **6. Testing Commands**

#### **Quick Health Check**
```bash
# Check all services
echo "=== Health Check ==="
echo "PostgreSQL: $(docker ps | grep postgres | wc -l) containers"
echo "Redis: $(docker ps | grep redis | wc -l) containers"
echo "API Server: $(curl -s http://localhost:3000/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo 'Not running')"
echo "Admin Dashboard: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3008 || echo 'Not running')"
```

#### **Comprehensive Test**
```bash
# Run the complete test suite
./test-complete-system.sh

# Run admin dashboard test
./test-admin-dashboard.sh

# Run individual service tests
./test-with-seed-data.sh
```

---

### **7. Troubleshooting Commands**

#### **Check Service Status**
```bash
# Check all containers
docker-compose ps

# Check specific service logs
docker logs shopping_cart-api-gateway-1 --tail 20
docker logs shopping_cart-user-service-1 --tail 20
docker logs shopping_cart-admin-dashboard-1 --tail 20

# Check if ports are in use
lsof -i :3000  # API Gateway
lsof -i :3001  # User Service
lsof -i :3002  # Product Service
lsof -i :3003  # Order Service
lsof -i :3004  # Cart Service
lsof -i :3006  # Notification Service
lsof -i :3007  # Wallet Service
lsof -i :3008  # Admin Dashboard
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
```

#### **Restart Services**
```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart api-gateway
docker-compose restart admin-dashboard

# Rebuild and restart
docker-compose up -d --build api-gateway
```

#### **Clean Up**
```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Remove all containers
docker-compose down --rmi all --volumes --remove-orphans

# Clean up Docker system
docker system prune -f
```

---

### **8. Development Commands**

#### **Local Development Setup**
```bash
# Start infrastructure only
docker-compose up -d postgres redis

# Start API server locally
ruby simple-rails-api.rb

# Start admin dashboard
docker-compose up -d admin-dashboard

# Access URLs:
# - Admin Dashboard: http://localhost:3008
# - API Server: http://localhost:3000
# - API Docs: http://localhost:3000/
```

#### **Database Management**
```bash
# Connect to PostgreSQL
docker exec -it shopping_cart-postgres-1 psql -U postgres

# List databases
docker exec shopping_cart-postgres-1 psql -U postgres -l

# Backup database
docker exec shopping_cart-postgres-1 pg_dump -U postgres user_service_development > backup.sql

# Restore database
docker exec -i shopping_cart-postgres-1 psql -U postgres user_service_development < backup.sql
```

---

### **9. Production Commands**

#### **Production Startup**
```bash
# Set production environment
export RAILS_ENV=production
export NODE_ENV=production

# Start with production settings
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check production logs
docker-compose logs -f --tail=100
```

#### **SSL/HTTPS Setup**
```bash
# Generate SSL certificates (if needed)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/nginx.key \
  -out nginx/ssl/nginx.crt

# Start with SSL
docker-compose -f docker-compose.yml -f docker-compose.ssl.yml up -d
```

---

## 🎯 **Recommended Startup Sequence**

### **For Development (Simple & Fast)**
```bash
# 1. Start infrastructure
docker-compose up -d postgres redis

# 2. Start API server
ruby simple-rails-api.rb

# 3. Start admin dashboard
docker-compose up -d admin-dashboard

# 4. Access your system
open http://localhost:3008
```

### **For Production (Complete Setup)**
```bash
# 1. Start everything
docker-compose up -d

# 2. Wait for services
sleep 30

# 3. Verify all services
docker-compose ps

# 4. Run health checks
./test-complete-system.sh
```

---

## 📊 **Service Ports Reference**

| Service | Port | URL | Status |
|---------|------|-----|--------|
| API Gateway | 3000 | http://localhost:3000 | ✅ Working |
| User Service | 3001 | http://localhost:3001 | 🔧 Fixed |
| Product Service | 3002 | http://localhost:3002 | 🔧 Fixed |
| Order Service | 3003 | http://localhost:3003 | 🔧 Fixed |
| Cart Service | 3004 | http://localhost:3004 | 🔧 Fixed |
| Notification Service | 3006 | http://localhost:3006 | 🔧 Fixed |
| Wallet Service | 3007 | http://localhost:3007 | 🔧 Fixed |
| Admin Dashboard | 3008 | http://localhost:3008 | ✅ Working |
| PostgreSQL | 5432 | localhost:5432 | ✅ Working |
| Redis | 6379 | localhost:6379 | ✅ Working |

---

## 🔑 **Login Credentials**

### **Admin Dashboard**
- **URL**: http://localhost:3008
- **Email**: admin@ecommerce.com
- **Password**: password123

### **API Testing**
```bash
# Test login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@ecommerce.com","password":"password123"}'
```

---

**🎉 Your microservices are ready to start! Choose the option that best fits your needs:**

- **Simple API Server**: Fast, reliable, single command
- **Full Microservices**: Complete setup, all 7 services
- **Hybrid Approach**: Start simple, add complexity later



