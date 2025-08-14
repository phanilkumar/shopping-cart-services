# 🚀 Quick Commands Reference

## ⚡ **Fast Start (Recommended)**

### **Start Everything (Simple Setup)**
```bash
./start-microservices.sh simple
```

### **Check Status**
```bash
./start-microservices.sh status
```

### **Stop Everything**
```bash
./start-microservices.sh stop
```

---

## 📋 **Individual Commands**

### **Infrastructure Only**
```bash
# Start PostgreSQL & Redis
docker-compose up -d postgres redis

# Check if running
docker ps | grep -E "(postgres|redis)"
```

### **Simple API Server**
```bash
# Start API server
ruby simple-rails-api.rb

# Test API
curl http://localhost:3000/health
```

### **Admin Dashboard**
```bash
# Start dashboard
docker-compose up -d admin-dashboard

# Access dashboard
open http://localhost:3008
```

### **Full Microservices**
```bash
# Start all Rails services
docker-compose up -d

# Check all services
docker-compose ps
```

---

## 🧪 **Testing Commands**

### **Quick Health Check**
```bash
# Test API server
curl http://localhost:3000/health

# Test admin dashboard
curl http://localhost:3008

# Test login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@ecommerce.com","password":"password123"}'
```

### **Run Complete Tests**
```bash
# Run all tests
./test-complete-system.sh

# Test admin dashboard only
./test-admin-dashboard.sh
```

---

## 🔧 **Troubleshooting**

### **Check What's Running**
```bash
# Check all containers
docker-compose ps

# Check specific service logs
docker logs shopping_cart-api-gateway-1 --tail 10
docker logs shopping_cart-admin-dashboard-1 --tail 10

# Check if ports are in use
lsof -i :3000  # API Server
lsof -i :3008  # Admin Dashboard
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
```

### **Restart Services**
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart admin-dashboard

# Rebuild and restart
docker-compose up -d --build admin-dashboard
```

### **Clean Up**
```bash
# Stop everything
docker-compose down

# Clean up completely
docker-compose down -v --rmi all --remove-orphans
```

---

## 🌐 **Access URLs**

| Service | URL | Status |
|---------|-----|--------|
| **Admin Dashboard** | http://localhost:3008 | ✅ Working |
| **API Server** | http://localhost:3000 | ✅ Working |
| **API Docs** | http://localhost:3000/ | ✅ Working |

---

## 🔑 **Login Credentials**

- **Email**: `admin@ecommerce.com`
- **Password**: `password123`

---

## 📊 **Service Ports**

| Service | Port | Purpose |
|---------|------|---------|
| 3000 | API Server | Backend API |
| 3008 | Admin Dashboard | React Frontend |
| 5432 | PostgreSQL | Database |
| 6379 | Redis | Cache |

---

## 🎯 **Most Used Commands**

```bash
# 1. Start everything (recommended)
./start-microservices.sh simple

# 2. Check if everything is working
./start-microservices.sh status

# 3. Open admin dashboard
open http://localhost:3008

# 4. Stop everything when done
./start-microservices.sh stop
```

---

**💡 Pro Tip**: Use `./start-microservices.sh simple` for the fastest and most reliable startup!

