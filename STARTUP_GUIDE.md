# 🚀 Microservices & Admin Dashboard Startup Guide

This guide will help you start all the microservices and the admin dashboard for monitoring them.

## 📋 Prerequisites

Before starting, ensure you have the following installed:

- **Ruby** (2.7+) with Bundler
- **Node.js** (16+) with npm
- **Docker** (optional, for containerized deployment)

## 🎯 Quick Start Options

### Option 1: Start Everything at Once (Recommended)
```bash
./start-all-services.sh
```
This will start all microservices and the admin dashboard automatically.

### Option 2: Start Microservices Only
```bash
./start-microservices-only.sh
```
Then start the admin dashboard separately:
```bash
cd admin-dashboard
./start.sh
```

### Option 3: Manual Start (Step by Step)

## 🔧 Manual Startup Process

### Step 1: Start Auth Service (Port 3001)
```bash
cd services/auth-service
bundle install
bundle exec rails server -p 3001 -d
cd ../..
```

### Step 2: Start OAuth Service (Port 3002)
```bash
cd services/oauth-service
bundle install
bundle exec rails server -p 3002 -d
cd ../..
```

### Step 3: Start User Service (Port 3003)
```bash
cd services/user-service
bundle install
bundle exec rails server -p 3003 -d
cd ../..
```

### Step 4: Start Admin Dashboard (Port 3000)
```bash
cd admin-dashboard
npm install
npm start
```

## 🐳 Docker Alternative

If you prefer using Docker:

### Start Microservices with Docker
```bash
# Build and start auth service
cd services/auth-service
docker build -t auth-service .
docker run -d --name auth-service -p 3001:3001 auth-service
cd ../..

# Build and start oauth service
cd services/oauth-service
docker build -t oauth-service .
docker run -d --name oauth-service -p 3002:3002 oauth-service
cd ../..

# Build and start user service
cd services/user-service
docker build -t user-service .
docker run -d --name user-service -p 3003:3003 user-service
cd ../..
```

### Start Admin Dashboard with Docker
```bash
cd admin-dashboard
docker-compose up --build
```

## 🌐 Access Points

Once everything is running, you can access:

- **Admin Dashboard**: http://localhost:3000
- **Auth Service**: http://localhost:3001
- **OAuth Service**: http://localhost:3002
- **User Service**: http://localhost:3003

## 📊 Admin Dashboard Features

The admin dashboard provides:

- **Real-time Service Monitoring**: Live status of all microservices
- **Service Management**: Restart services with one click
- **Live Logs**: View real-time logs from each service
- **System Overview**: Comprehensive statistics and metrics
- **Health Checks**: Automatic health monitoring every 30 seconds

## 🔍 Troubleshooting

### Port Already in Use
If you get a "port already in use" error:
```bash
# Find what's using the port
lsof -i :3001  # Replace with the port number

# Kill the process
kill -9 <PID>
```

### Service Not Starting
1. Check if Ruby and Bundler are installed:
   ```bash
   ruby --version
   bundle --version
   ```

2. Check if Node.js is installed:
   ```bash
   node --version
   npm --version
   ```

3. Check service logs:
   ```bash
   # For Rails services
   tail -f services/auth-service/log/development.log
   ```

### Admin Dashboard Not Connecting
1. Ensure all microservices are running
2. Check that ports 3001, 3002, and 3003 are accessible
3. Verify health endpoints are working:
   ```bash
   curl http://localhost:3001/health
   curl http://localhost:3002/health
   curl http://localhost:3003/health
   ```

## 🛑 Stopping Services

### Stop All Services
```bash
# Stop Rails servers
pkill -f "rails server"

# Stop Docker containers (if using Docker)
docker stop auth-service oauth-service user-service
docker rm auth-service oauth-service user-service

# Stop admin dashboard (Ctrl+C in the terminal where it's running)
```

### Stop Individual Services
```bash
# Stop specific Rails server
pkill -f "rails server -p 3001"

# Stop specific Docker container
docker stop auth-service
```

## 📝 Service Configuration

### Health Check Endpoints
Each service should have a `/health` endpoint that returns:
```json
{
  "health": 100,
  "uptime": "2h 30m",
  "version": "1.0.0"
}
```

### Metrics Endpoints (Optional)
For enhanced monitoring, services can implement `/metrics`:
```json
{
  "requestsPerMinute": 150,
  "averageResponseTime": 45,
  "errorRate": 0.5,
  "activeConnections": 25,
  "memoryUsage": 75,
  "cpuUsage": 30
}
```

### Logs Endpoints (Optional)
For log viewing, services can implement `/logs?limit=50`:
```json
{
  "logs": [
    {
      "id": "1",
      "timestamp": "2024-01-15T10:30:00Z",
      "level": "info",
      "message": "Service started successfully",
      "service": "auth-service"
    }
  ]
}
```

## 🔄 Auto-restart Scripts

For development, you can use tools like `nodemon` or `foreman`:

### Using Foreman
Create a `Procfile`:
```
auth: cd services/auth-service && bundle exec rails server -p 3001
oauth: cd services/oauth-service && bundle exec rails server -p 3002
user: cd services/user-service && bundle exec rails server -p 3003
admin: cd admin-dashboard && npm start
```

Then run:
```bash
foreman start
```

## 📈 Monitoring

The admin dashboard automatically:
- Refreshes service status every 30 seconds
- Updates logs every 10 seconds
- Calculates system statistics in real-time
- Provides visual indicators for service health

## 🆘 Getting Help

If you encounter issues:
1. Check the service logs in `services/*/log/`
2. Verify all prerequisites are installed
3. Ensure ports are not in use by other applications
4. Check the admin dashboard console for error messages
