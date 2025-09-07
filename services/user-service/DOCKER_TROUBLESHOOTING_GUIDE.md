# 🐳 Docker Troubleshooting Guide

## ✅ **ISSUE RESOLVED: Docker Commands Now Working!**

Your Docker setup is now fully functional. Here's what was wrong and how to prevent it in the future.

---

## 🔍 **What Was Wrong**

**Problem**: Web container was showing as "unhealthy" and failing to start properly.

**Root Cause**: **Pending database migrations** - The Rails application couldn't start because the database schema was out of sync.

**Error**: `ActiveRecord::PendingMigrationError - Migrations are pending`

---

## 🛠️ **How We Fixed It**

### **Step 1: Identified the Issue**
```bash
# Check container status
docker-compose ps
# Result: web container was "unhealthy"

# Check logs
docker-compose logs web
# Result: Found pending migrations error
```

### **Step 2: Ran Database Migrations**
```bash
# Run migrations in the web container
docker-compose exec web bundle exec rails db:migrate
# Result: Successfully migrated 3 pending migrations
```

### **Step 3: Verified Fix**
```bash
# Check container status again
docker-compose ps
# Result: All containers now "healthy"

# Test application
curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/
# Result: 200 (success)
```

---

## 🚀 **Working Docker Commands**

### **Basic Commands**
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart all services
docker-compose restart

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### **Development Commands**
```bash
# Run Rails console
docker-compose exec web bundle exec rails console

# Run database migrations
docker-compose exec web bundle exec rails db:migrate

# Reset database
docker-compose exec web bundle exec rails db:reset

# Run tests
docker-compose exec web bundle exec rails test

# Run RSpec tests
docker-compose exec web bundle exec rspec
```

### **Using the Convenience Script**
```bash
# Make script executable
chmod +x docker.sh

# Use the script
./docker.sh up          # Start services
./docker.sh down        # Stop services
./docker.sh restart     # Restart services
./docker.sh logs        # View logs
./docker.sh migrate     # Run migrations
./docker.sh console     # Open Rails console
./docker.sh status      # Check status
```

---

## 🔧 **Common Docker Issues & Solutions**

### **1. Container Won't Start**
```bash
# Check logs
docker-compose logs [service-name]

# Common causes:
# - Pending migrations (run: docker-compose exec web bundle exec rails db:migrate)
# - Port conflicts (check if port 3001 is already in use)
# - Database connection issues (check if db container is healthy)
```

### **2. Database Connection Issues**
```bash
# Check database container
docker-compose ps db

# Check database logs
docker-compose logs db

# Reset database if needed
docker-compose exec web bundle exec rails db:reset
```

### **3. Port Already in Use**
```bash
# Check what's using port 3001
lsof -i :3001

# Kill process if needed
kill -9 [PID]

# Or change port in docker-compose.yml
```

### **4. Container Stuck in "Restarting" State**
```bash
# Stop all containers
docker-compose down

# Remove containers
docker-compose rm -f

# Rebuild and start
docker-compose up -d --build
```

### **5. Permission Issues**
```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Make scripts executable
chmod +x docker.sh
chmod +x bin/*
```

---

## 📊 **Health Check Endpoints**

### **Application Health**
```bash
# Check if app is responding
curl http://localhost:3001/

# Check health endpoint (if available)
curl http://localhost:3001/health
```

### **Database Health**
```bash
# Check database connection
docker-compose exec web bundle exec rails runner "puts ActiveRecord::Base.connection.active?"

# Check database status
docker-compose exec db pg_isready -U postgres
```

### **Redis Health**
```bash
# Check Redis connection
docker-compose exec redis redis-cli ping
```

---

## 🎯 **Quick Troubleshooting Checklist**

When Docker commands aren't working:

1. **Check container status**: `docker-compose ps`
2. **Check logs**: `docker-compose logs [service-name]`
3. **Look for common errors**:
   - Pending migrations
   - Port conflicts
   - Database connection issues
   - Permission problems
4. **Run migrations**: `docker-compose exec web bundle exec rails db:migrate`
5. **Restart services**: `docker-compose restart`
6. **Rebuild if needed**: `docker-compose up -d --build`

---

## 🌐 **Access Your Application**

- **Main Application**: http://localhost:3001
- **Login Page**: http://localhost:3001/users/sign_in
- **Security Dashboard**: http://localhost:3001/security/dashboard
- **Rate Limiting Test**: http://localhost:3001/security/rate-limit-test

---

## 📝 **Useful Docker Commands Reference**

```bash
# Container Management
docker-compose up -d                    # Start in background
docker-compose down                     # Stop and remove containers
docker-compose restart                  # Restart services
docker-compose ps                       # Show status
docker-compose logs -f                  # Follow logs

# Database Operations
docker-compose exec web bundle exec rails db:migrate
docker-compose exec web bundle exec rails db:reset
docker-compose exec web bundle exec rails db:seed

# Development
docker-compose exec web bundle exec rails console
docker-compose exec web bundle exec rails test
docker-compose exec web bundle exec rspec

# Cleanup
docker-compose down -v                  # Remove volumes
docker-compose down --rmi all           # Remove images
docker system prune                     # Clean up everything
```

---

## ✅ **Current Status**

- ✅ **Docker**: Working properly
- ✅ **Database**: Connected and migrated
- ✅ **Redis**: Connected and healthy
- ✅ **Web Application**: Running on port 3001
- ✅ **All Services**: Healthy and operational

Your Docker setup is now fully functional! 🎉
