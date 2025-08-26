# Docker Setup for User Service

This document explains how to run the User Service using Docker with support for both email and phone OTP authentication.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

### 1. Build and Start Services

```bash
# Build the Docker images
docker-compose build

# Start all services (database, Redis, and web application)
docker-compose up -d

# View logs
docker-compose logs -f web
```

### 2. Access the Application

- **Login Page**: http://localhost:3001/users/sign_in
- **Database**: localhost:5432
- **Redis**: localhost:6379

### 3. Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (this will delete all data)
docker-compose down -v
```

## Services

### 1. Web Application (Rails)
- **Port**: 3001
- **Environment**: Development
- **Features**: 
  - Email/Password authentication
  - Phone OTP authentication
  - Mobile-optimized UI
  - Hotwire/Stimulus for interactivity

### 2. PostgreSQL Database
- **Port**: 5432
- **Database**: user_service_development
- **User**: postgres
- **Password**: password

### 3. Redis Cache
- **Port**: 6379
- **Purpose**: OTP storage and caching
- **Data Persistence**: Yes (redis_data volume)

## Docker Commands

### Basic Operations

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f web
docker-compose logs -f db
docker-compose logs -f redis

# Restart services
docker-compose restart

# Rebuild and restart
docker-compose up -d --build
```

### Development Commands

```bash
# Run Rails console
docker-compose exec web rails console

# Run database migrations
docker-compose exec web rails db:migrate

# Reset database
docker-compose exec web rails db:reset

# Run tests
docker-compose exec web rails test

# Check service health
docker-compose ps
```

### Data Management

```bash
# Backup database
docker-compose exec db pg_dump -U postgres user_service_development > backup.sql

# Restore database
docker-compose exec -T db psql -U postgres user_service_development < backup.sql

# Clear Redis cache
docker-compose exec redis redis-cli FLUSHALL
```

## Configuration

### Environment Variables

The following environment variables are configured in `docker-compose.yml`:

- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `RAILS_ENV`: Development environment
- `RAILS_SERVE_STATIC_FILES`: Enable static file serving
- `RAILS_LOG_TO_STDOUT`: Log to stdout for Docker

### Volumes

- `postgres_data`: PostgreSQL data persistence
- `redis_data`: Redis data persistence
- `bundle_cache`: Ruby gems cache

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using the port
   lsof -i :3001
   lsof -i :5432
   lsof -i :6379
   
   # Stop conflicting services
   docker-compose down
   ```

2. **Database Connection Issues**
   ```bash
   # Check database health
   docker-compose exec db pg_isready -U postgres
   
   # Restart database
   docker-compose restart db
   ```

3. **Redis Connection Issues**
   ```bash
   # Check Redis health
   docker-compose exec redis redis-cli ping
   
   # Restart Redis
   docker-compose restart redis
   ```

4. **Application Not Starting**
   ```bash
   # Check application logs
   docker-compose logs web
   
   # Check if all dependencies are healthy
   docker-compose ps
   ```

### Reset Everything

```bash
# Stop all services and remove volumes
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up -d
```

## Development Workflow

### 1. First Time Setup

```bash
# Clone the repository
git clone <repository-url>
cd user-service

# Build and start services
docker-compose build
docker-compose up -d

# Wait for services to be healthy
docker-compose ps

# Access the application
open http://localhost:3001/users/sign_in
```

### 2. Daily Development

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f web

# Make code changes (they will be reflected immediately due to volume mounting)

# Stop services when done
docker-compose down
```

### 3. Testing OTP Functionality

1. Navigate to http://localhost:3001/users/sign_in
2. Click on "Phone OTP" tab
3. Enter a 10-digit phone number (e.g., 9876543210)
4. Click "Send OTP"
5. Use the test OTP: **123456**
6. Enter the OTP in the separated fields (12-34-56)
7. Click "Verify & Login"

## Health Checks

The Docker Compose configuration includes health checks for all services:

- **Database**: Checks if PostgreSQL is ready to accept connections
- **Redis**: Checks if Redis is responding to ping commands
- **Web**: Checks if the Rails application is responding on port 3001

You can check the health status with:

```bash
docker-compose ps
```

## Performance Optimization

### Memory Usage

- The application uses jemalloc for reduced memory usage
- Redis is configured for optimal performance
- PostgreSQL is configured with reasonable defaults

### Caching

- Rails caching is enabled by default for OTP functionality
- Redis is used as the cache store
- OTP codes expire after 30 minutes

## Security Notes

- This is a development setup
- Database passwords are hardcoded for simplicity
- Redis is exposed on localhost only
- For production, use proper secrets management

## Support

If you encounter issues:

1. Check the logs: `docker-compose logs -f`
2. Verify service health: `docker-compose ps`
3. Check the troubleshooting section above
4. Ensure all prerequisites are installed
