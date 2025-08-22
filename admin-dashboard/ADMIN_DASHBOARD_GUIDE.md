# Admin Dashboard Guide

## Overview

The Admin Dashboard is a comprehensive monitoring and management interface for the shopping cart microservices infrastructure. It provides real-time status monitoring, service management, and operational insights.

## Features

### 🔍 **Service Monitoring**
- **Real-time Status**: Monitor all microservices health and status
- **Health Metrics**: View service health percentages and uptime
- **Port Information**: See which ports each service is running on
- **Version Tracking**: Monitor service versions

### 🚀 **Service Management**
- **Restart Functionality**: Restart individual microservices
- **Service Recovery**: Automatic recovery for failed services
- **Container Management**: Direct Docker Compose integration

### 📊 **Dashboard Statistics**
- **Total Services**: Count of all configured services
- **Online Services**: Number of currently running services
- **Error Rate**: Percentage of offline services
- **Response Times**: Average response times across services

## Microservices Monitored

The admin dashboard monitors the following microservices:

| Service | Port | Purpose | Health Endpoint |
|---------|------|---------|-----------------|
| API Gateway | 3000 | Main API entry point | `/health` |
| User Service | 3001 | User management & auth | `/health` |
| Product Service | 3002 | Product catalog | `/health` |
| Order Service | 3003 | Order processing | `/health` |
| Cart Service | 3004 | Shopping cart | `/health` |
| Frontend | 3005 | React frontend | `/` |
| Notification Service | 3006 | Notifications | `/health` |
| Wallet Service | 3007 | Payment & wallet | `/health` |
| Admin Dashboard | 3008 | This dashboard | `/` |

## Restart Button Functionality

### 🎯 **Purpose**
The restart button allows administrators to restart individual microservices without affecting the entire system. This is useful for:

- **Service Recovery**: Restart services that have crashed or become unresponsive
- **Configuration Updates**: Apply new configurations by restarting services
- **Memory Issues**: Clear memory leaks by restarting services
- **Troubleshooting**: Isolate and resolve service-specific issues

### ⚙️ **How It Works**
1. **Docker Compose Integration**: Uses `docker compose restart <service-name>`
2. **Container Management**: Stops and starts the specific service container
3. **Health Monitoring**: Automatically checks service health after restart
4. **Status Updates**: Updates the dashboard to reflect new service status

### 🔧 **Technical Implementation**
- **API Endpoint**: `/api/admin/restart-service`
- **Backend Server**: Express.js server on port 3009
- **Docker Socket**: Direct access to Docker daemon
- **Service Mapping**: Maps dashboard service IDs to Docker service names

### ⚠️ **Important Notes**
- **Service Downtime**: Restarting a service causes brief downtime
- **Dependencies**: Some services may depend on others
- **Data Persistence**: Restarting doesn't affect persistent data
- **Logs**: Restart events are logged for audit purposes

## Usage Instructions

### 🔐 **Access**
1. Open `http://localhost:3008`
2. Login with admin credentials:
   - Email: `admin@example.com`
   - Password: `admin123`

### 📊 **Monitoring**
1. **View Service Status**: All services are displayed with real-time status
2. **Check Health**: Green indicators show healthy services
3. **Monitor Uptime**: Track how long services have been running
4. **Review Logs**: Access service logs for troubleshooting

### 🚀 **Service Management**
1. **Identify Issues**: Look for red (offline) or yellow (warning) indicators
2. **Restart Services**: Click the "Restart" button for problematic services
3. **Monitor Recovery**: Watch for services to come back online
4. **Verify Health**: Ensure services are responding after restart

### 📈 **Dashboard Statistics**
- **Total Services**: Shows all configured microservices
- **Online Count**: Number of currently running services
- **Error Rate**: Percentage of services that are offline
- **Response Times**: Average response times across all services

## Troubleshooting

### 🔍 **Common Issues**

**Service Shows Offline**
- Check if the service container is running
- Verify the service port is accessible
- Check service logs for errors
- Try restarting the service

**Restart Button Not Working**
- Ensure Docker is running
- Check if the admin dashboard API server is running
- Verify Docker Compose access permissions
- Check browser console for errors

**Health Endpoints Not Responding**
- Verify service health endpoints are implemented
- Check if services are properly configured
- Ensure CORS is enabled for cross-origin requests

### 🛠️ **Debugging Steps**
1. **Check Container Status**: `docker compose ps`
2. **View Service Logs**: `docker compose logs <service-name>`
3. **Test Health Endpoints**: `curl http://localhost:<port>/health`
4. **Verify API Server**: `curl http://localhost:3009/health`

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Admin         │    │   Admin          │    │   Docker        │
│   Dashboard     │───▶│   Dashboard API  │───▶│   Compose       │
│   (React)       │    │   (Express)      │    │   Services      │
│   Port: 3008    │    │   Port: 3009     │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Security Considerations

- **Authentication Required**: Admin login required for access
- **Docker Socket Access**: Limited to restart operations
- **CORS Configuration**: Properly configured for security
- **Error Handling**: Secure error messages without sensitive data

## Future Enhancements

- **Service Scaling**: Scale services up/down
- **Configuration Management**: Update service configurations
- **Metrics Dashboard**: Detailed performance metrics
- **Alert System**: Notifications for service issues
- **Backup Management**: Service backup and restore



