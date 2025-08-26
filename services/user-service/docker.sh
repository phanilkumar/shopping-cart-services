#!/bin/bash

# Docker convenience script for User Service
# Usage: ./docker.sh [command]

set -e

case "$1" in
  "build")
    echo "Building Docker images..."
    docker-compose build
    ;;
  "up")
    echo "Starting services..."
    docker-compose up -d
    echo "Services started! Access the application at: http://localhost:3001/users/sign_in"
    ;;
  "down")
    echo "Stopping services..."
    docker-compose down
    ;;
  "restart")
    echo "Restarting services..."
    docker-compose down
    docker-compose up -d
    echo "Services restarted! Access the application at: http://localhost:3001/users/sign_in"
    ;;
  "logs")
    echo "Showing logs..."
    docker-compose logs -f
    ;;
  "logs-web")
    echo "Showing web service logs..."
    docker-compose logs -f web
    ;;
  "logs-db")
    echo "Showing database logs..."
    docker-compose logs -f db
    ;;
  "logs-redis")
    echo "Showing Redis logs..."
    docker-compose logs -f redis
    ;;
  "status")
    echo "Service status:"
    docker-compose ps
    ;;
  "console")
    echo "Opening Rails console..."
    docker-compose exec web rails console
    ;;
  "migrate")
    echo "Running database migrations..."
    docker-compose exec web rails db:migrate
    ;;
  "reset")
    echo "Resetting database..."
    docker-compose exec web rails db:reset
    ;;
  "test")
    echo "Running tests..."
    docker-compose exec web rails test
    ;;
  "clean")
    echo "Cleaning up everything..."
    docker-compose down -v --rmi all
    echo "Cleanup complete!"
    ;;
  "rebuild")
    echo "Rebuilding from scratch..."
    docker-compose down -v
    docker-compose build --no-cache
    docker-compose up -d
    echo "Rebuild complete! Access the application at: http://localhost:3001/users/sign_in"
    ;;
  *)
    echo "Usage: $0 {build|up|down|restart|logs|logs-web|logs-db|logs-redis|status|console|migrate|reset|test|clean|rebuild}"
    echo ""
    echo "Commands:"
    echo "  build     - Build Docker images"
    echo "  up        - Start services"
    echo "  down      - Stop services"
    echo "  restart   - Restart services"
    echo "  logs      - Show all logs"
    echo "  logs-web  - Show web service logs"
    echo "  logs-db   - Show database logs"
    echo "  logs-redis- Show Redis logs"
    echo "  status    - Show service status"
    echo "  console   - Open Rails console"
    echo "  migrate   - Run database migrations"
    echo "  reset     - Reset database"
    echo "  test      - Run tests"
    echo "  clean     - Clean up everything"
    echo "  rebuild   - Rebuild from scratch"
    exit 1
    ;;
esac
