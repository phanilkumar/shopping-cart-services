# 🛒 E-commerce Microservices Platform

A comprehensive, production-ready e-commerce platform built with microservices architecture, featuring a React admin dashboard, multiple backend services, and complete testing infrastructure.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │    │   User Service  │    │ Product Service │
│   (Port 3000)   │    │   (Port 3001)   │    │  (Port 3002)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Order Service  │    │   Cart Service  │    │  Wallet Service │
│   (Port 3003)   │    │   (Port 3004)   │    │  (Port 3007)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│Notification Svc │    │   Frontend      │    │ Admin Dashboard │
│  (Port 3006)    │    │  (Port 3005)    │    │  (Port 3008)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 18+ (for local development)
- Ruby 3.2+ (for local development)

### 1. Clone and Setup
```bash
git clone <repository-url>
cd shopping_cart
```

### 2. Start the Application
```bash
# Start all services
docker-compose up -d

# Or start specific services
docker-compose up postgres redis admin-dashboard -d
```

### 3. Test the Application
```bash
# Run the comprehensive test script
./test-application.sh
```

### 4. Access the Application
- **Admin Dashboard**: http://localhost:3008
- **Frontend**: http://localhost:3005
- **API Gateway**: http://localhost:3000

## 📊 Services Overview

### 🔐 Authentication & Users
- **User Service** (Port 3001): User management, authentication, profiles
- **API Gateway** (Port 3000): Centralized routing, authentication, rate limiting

### 🛍️ E-commerce Core
- **Product Service** (Port 3002): Product catalog, inventory, categories
- **Cart Service** (Port 3004): Shopping cart management, saved items
- **Order Service** (Port 3003): Order processing, payments, shipping
- **Wallet Service** (Port 3007): Digital wallet, transactions, transfers

### 📱 Frontend & Admin
- **Frontend** (Port 3005): Customer-facing React application
- **Admin Dashboard** (Port 3008): Comprehensive admin interface

### 🔔 Communication
- **Notification Service** (Port 3006): Email, SMS, push notifications

### 🗄️ Infrastructure
- **PostgreSQL**: Primary database
- **Redis**: Caching and session management

## 🎯 Admin Dashboard Features

### 📈 Dashboard Analytics
- Real-time sales metrics
- User activity tracking
- Revenue analytics
- Order statistics
- Interactive charts and graphs

### 👥 User Management
- User registration and profiles
- Role-based access control
- User activity monitoring
- Account management

### 📦 Product Management
- Product catalog management
- Inventory tracking
- Category management
- Product analytics

### 🛒 Order Management
- Order processing workflow
- Payment status tracking
- Shipping management
- Order analytics

### 🛍️ Cart Management
- Shopping cart monitoring
- Abandoned cart analysis
- Cart conversion tracking

### 💰 Wallet Management
- Digital wallet administration
- Transaction monitoring
- Transfer management
- Financial analytics

### 🔔 Notification Management
- Email campaign management
- SMS notifications
- Push notification system
- Template management

### 📊 Analytics & Reports
- Comprehensive reporting
- Data visualization
- Export capabilities
- Performance metrics

## 🛠️ Technology Stack

### Backend Services
- **Framework**: Ruby on Rails 7 (API mode)
- **Database**: PostgreSQL 14
- **Cache**: Redis 7
- **Authentication**: JWT + Devise
- **Payment**: Stripe integration
- **File Storage**: AWS S3
- **Search**: Elasticsearch
- **Background Jobs**: Sidekiq
- **Monitoring**: Sentry, Lograge

### Frontend Applications
- **Framework**: React 18 with TypeScript
- **UI Library**: Material-UI (MUI)
- **State Management**: Redux Toolkit
- **Data Fetching**: React Query
- **Charts**: Recharts
- **Forms**: Formik + Yup
- **Routing**: React Router DOM

### DevOps & Infrastructure
- **Containerization**: Docker & Docker Compose
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana
- **Security**: Rate limiting, CORS, input validation

## 🔧 Development

### Local Development Setup
```bash
# Install dependencies for admin dashboard
cd admin-dashboard
npm install

# Install dependencies for frontend
cd ../frontend
npm install

# Start development servers
npm start
```

### Database Setup
```bash
# Create databases
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE user_service_dev;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE product_service_dev;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE order_service_dev;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE cart_service_dev;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE notification_service_dev;"
docker exec shopping_cart-postgres-1 psql -U postgres -c "CREATE DATABASE wallet_service_dev;"
```

### Running Tests
```bash
# Test the application
./test-application.sh

# Check service health
curl http://localhost:3008/health
```

## 📋 API Documentation

### Authentication Endpoints
```
POST /api/v1/auth/login
POST /api/v1/auth/register
POST /api/v1/auth/logout
GET  /api/v1/auth/profile
```

### User Management
```
GET    /api/v1/users
POST   /api/v1/users
GET    /api/v1/users/:id
PUT    /api/v1/users/:id
DELETE /api/v1/users/:id
```

### Product Management
```
GET    /api/v1/products
POST   /api/v1/products
GET    /api/v1/products/:id
PUT    /api/v1/products/:id
DELETE /api/v1/products/:id
```

### Order Management
```
GET    /api/v1/orders
POST   /api/v1/orders
GET    /api/v1/orders/:id
PUT    /api/v1/orders/:id/status
```

### Wallet Management
```
GET    /api/v1/wallets
POST   /api/v1/wallets
GET    /api/v1/wallets/:id
POST   /api/v1/wallets/:id/transactions
```

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Role-based Access Control**: Granular permissions
- **Rate Limiting**: API protection against abuse
- **Input Validation**: Comprehensive data validation
- **CORS Configuration**: Cross-origin request handling
- **Encryption**: Sensitive data encryption
- **Audit Logging**: Complete activity tracking

## 📈 Monitoring & Analytics

### Health Checks
- Service health monitoring
- Database connectivity checks
- External service status
- Performance metrics

### Logging
- Structured logging with Lograge
- Error tracking with Sentry
- Request/response logging
- Performance monitoring

### Metrics
- Real-time dashboard metrics
- Business analytics
- Performance indicators
- User behavior tracking

## 🚀 Deployment

### Production Deployment
```bash
# Build production images
docker-compose -f docker-compose.prod.yml build

# Deploy to production
docker-compose -f docker-compose.prod.yml up -d
```

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:password@host:5432/database
REDIS_URL=redis://host:6379/0

# Authentication
JWT_SECRET_KEY=your-secret-key

# External Services
STRIPE_SECRET_KEY=your-stripe-key
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the documentation
- Review the test scripts

## 🎉 Success!

Your e-commerce platform is now running with:
- ✅ Complete microservices architecture
- ✅ React admin dashboard
- ✅ Comprehensive testing
- ✅ Production-ready configuration
- ✅ Security features
- ✅ Monitoring and analytics

**Next Steps:**
1. Access the admin dashboard at http://localhost:3008
2. Explore the different management sections
3. Add your first products and users
4. Configure payment and notification settings
5. Monitor analytics and performance

Happy selling! 🚀
