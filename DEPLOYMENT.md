# Deployment Guide

This guide covers the deployment of the Ecommerce Microservices Application across different environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Development Environment](#development-environment)
3. [Staging Environment](#staging-environment)
4. [Production Environment](#production-environment)
5. [Monitoring and Logging](#monitoring-and-logging)
6. [Backup and Recovery](#backup-and-recovery)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Git**: Version 2.30 or higher
- **Memory**: Minimum 8GB RAM (16GB recommended)
- **Storage**: Minimum 50GB free space
- **CPU**: 4 cores minimum (8 cores recommended)

### Network Requirements

- **Ports**: 80, 443, 3000-3006, 5432, 6379
- **Firewall**: Configure to allow HTTP/HTTPS traffic
- **SSL Certificate**: For production environments

## Development Environment

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd shopping_cart
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start all services**
   ```bash
   docker-compose up -d
   ```

4. **Initialize databases**
   ```bash
   docker-compose exec api-gateway rails db:create db:migrate
   docker-compose exec user-service rails db:create db:migrate
   docker-compose exec product-service rails db:create db:migrate
   docker-compose exec order-service rails db:create db:migrate
   docker-compose exec cart-service rails db:create db:migrate
   ```

5. **Seed data (optional)**
   ```bash
   docker-compose exec api-gateway rails db:seed
   docker-compose exec user-service rails db:seed
   docker-compose exec product-service rails db:seed
   ```

6. **Access the application**
   - Frontend: http://localhost:3005
   - API Gateway: http://localhost:3000
   - Health Check: http://localhost:3000/health

### Development Workflow

1. **Running tests**
   ```bash
   # All services
   docker-compose exec api-gateway rspec
   docker-compose exec user-service rspec
   docker-compose exec product-service rspec
   docker-compose exec order-service rspec
   docker-compose exec cart-service rspec
   
   # Frontend
   cd frontend && npm test
   ```

2. **Code quality checks**
   ```bash
   # Ruby linting
   docker-compose exec api-gateway rubocop
   docker-compose exec user-service rubocop
   
   # Frontend linting
   cd frontend && npm run lint
   ```

3. **Database migrations**
   ```bash
   docker-compose exec api-gateway rails db:migrate
   docker-compose exec user-service rails db:migrate
   # Repeat for other services
   ```

## Staging Environment

### Setup

1. **Create staging environment file**
   ```bash
   cp docker-compose.yml docker-compose.staging.yml
   # Edit with staging-specific configurations
   ```

2. **Configure staging environment variables**
   ```bash
   cp .env.example .env.staging
   # Edit with staging configurations
   ```

3. **Deploy to staging**
   ```bash
   docker-compose -f docker-compose.staging.yml --env-file .env.staging up -d
   ```

### Staging Configuration

- Use staging databases
- Enable detailed logging
- Configure staging-specific external services
- Set up staging monitoring

## Production Environment

### Pre-deployment Checklist

- [ ] SSL certificates obtained and configured
- [ ] Domain names configured
- [ ] Database backups configured
- [ ] Monitoring and alerting set up
- [ ] Security audit completed
- [ ] Performance testing completed
- [ ] Load balancing configured
- [ ] CDN configured (if applicable)

### Production Setup

1. **Create production environment file**
   ```bash
   cp docker-compose.prod.yml docker-compose.production.yml
   # Edit with production-specific configurations
   ```

2. **Configure production environment variables**
   ```bash
   cp .env.example .env.production
   # Edit with production configurations
   ```

3. **Set up SSL certificates**
   ```bash
   mkdir -p nginx/ssl
   # Copy your SSL certificates to nginx/ssl/
   ```

4. **Deploy to production**
   ```bash
   docker-compose -f docker-compose.production.yml --env-file .env.production up -d
   ```

### Production Configuration

#### Environment Variables

```bash
# Database
POSTGRES_PASSWORD=your-secure-password
POSTGRES_USER=postgres
POSTGRES_DB=ecommerce_prod

# JWT
JWT_SECRET_KEY=your-very-secure-jwt-secret

# Redis
REDIS_URL=redis://redis:6379

# External Services
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# API URLs
REACT_APP_API_URL=https://your-domain.com/api
```

#### Security Considerations

1. **SSL/TLS Configuration**
   - Use strong SSL certificates
   - Configure HSTS headers
   - Enable HTTP/2

2. **Firewall Configuration**
   ```bash
   # Allow only necessary ports
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw allow 22/tcp  # SSH
   ufw enable
   ```

3. **Database Security**
   - Use strong passwords
   - Enable SSL connections
   - Restrict network access
   - Regular security updates

4. **Application Security**
   - Enable rate limiting
   - Configure CORS properly
   - Use secure headers
   - Regular dependency updates

## Monitoring and Logging

### Application Monitoring

1. **Health Checks**
   ```bash
   # Check all services
   curl http://your-domain.com/health
   ```

2. **Log Monitoring**
   ```bash
   # View logs
   docker-compose logs -f api-gateway
   docker-compose logs -f user-service
   # Repeat for other services
   ```

3. **Performance Monitoring**
   - Set up Prometheus/Grafana
   - Monitor response times
   - Track error rates
   - Monitor resource usage

### Log Aggregation

1. **ELK Stack Setup**
   ```bash
   # Add to docker-compose.production.yml
   elasticsearch:
     image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
     environment:
       - discovery.type=single-node
     ports:
       - "9200:9200"
   
   kibana:
     image: docker.elastic.co/kibana/kibana:7.17.0
     ports:
       - "5601:5601"
     depends_on:
       - elasticsearch
   
   logstash:
     image: docker.elastic.co/logstash/logstash:7.17.0
     volumes:
       - ./logstash/pipeline:/usr/share/logstash/pipeline
     depends_on:
       - elasticsearch
   ```

2. **Log Configuration**
   ```ruby
   # config/environments/production.rb
   config.log_level = :info
   config.log_tags = [:request_id, :remote_ip]
   config.logger = ActiveSupport::Logger.new(STDOUT)
   ```

## Backup and Recovery

### Database Backups

1. **Automated Backups**
   ```bash
   # Create backup script
   #!/bin/bash
   DATE=$(date +%Y%m%d_%H%M%S)
   docker-compose exec -T postgres pg_dump -U postgres ecommerce_prod > backup_$DATE.sql
   ```

2. **Backup Schedule**
   ```bash
   # Add to crontab
   0 2 * * * /path/to/backup-script.sh
   ```

3. **Backup Verification**
   ```bash
   # Test restore
   docker-compose exec -T postgres psql -U postgres ecommerce_test < backup_20231201_020000.sql
   ```

### Application Backups

1. **Configuration Backups**
   ```bash
   # Backup configuration files
   tar -czf config_backup_$(date +%Y%m%d).tar.gz .env.production docker-compose.production.yml
   ```

2. **File Uploads Backup**
   ```bash
   # Backup uploaded files
   rsync -av /path/to/uploads/ /backup/uploads/
   ```

## Troubleshooting

### Common Issues

1. **Service Not Starting**
   ```bash
   # Check logs
   docker-compose logs service-name
   
   # Check resource usage
   docker stats
   
   # Restart service
   docker-compose restart service-name
   ```

2. **Database Connection Issues**
   ```bash
   # Check database status
   docker-compose exec postgres pg_isready
   
   # Check connection from service
   docker-compose exec api-gateway rails db:version
   ```

3. **Memory Issues**
   ```bash
   # Check memory usage
   docker stats
   
   # Increase memory limits in docker-compose.yml
   ```

4. **Network Issues**
   ```bash
   # Check network connectivity
   docker-compose exec api-gateway ping user-service
   
   # Check DNS resolution
   docker-compose exec api-gateway nslookup user-service
   ```

### Performance Optimization

1. **Database Optimization**
   ```sql
   -- Add indexes
   CREATE INDEX idx_users_email ON users(email);
   CREATE INDEX idx_orders_user_id ON orders(user_id);
   ```

2. **Caching Strategy**
   ```ruby
   # Redis caching
   Rails.cache.fetch("user:#{user_id}", expires_in: 1.hour) do
     User.find(user_id)
   end
   ```

3. **Load Balancing**
   ```nginx
   # Nginx load balancer configuration
   upstream api_servers {
       server api-gateway-1:3000;
       server api-gateway-2:3000;
       server api-gateway-3:3000;
   }
   ```

### Emergency Procedures

1. **Service Rollback**
   ```bash
   # Rollback to previous version
   docker-compose -f docker-compose.production.yml down
   docker image tag previous-version current-version
   docker-compose -f docker-compose.production.yml up -d
   ```

2. **Database Recovery**
   ```bash
   # Restore from backup
   docker-compose exec -T postgres psql -U postgres ecommerce_prod < backup.sql
   ```

3. **Emergency Maintenance Mode**
   ```bash
   # Enable maintenance mode
   echo "Maintenance in progress" > /usr/share/nginx/html/maintenance.html
   ```

## Support

For additional support:

1. Check the application logs
2. Review the monitoring dashboards
3. Consult the troubleshooting section
4. Contact the development team
5. Check the GitHub issues page

## Security Updates

Regular security updates are crucial:

1. **Dependency Updates**
   ```bash
   # Update Ruby gems
   bundle update
   
   # Update npm packages
   npm update
   ```

2. **Docker Image Updates**
   ```bash
   # Pull latest base images
   docker-compose pull
   ```

3. **Security Scanning**
   ```bash
   # Run security scans
   docker run --rm -v $(pwd):/app aquasec/trivy fs /app
   ```



