#!/bin/bash

# Standardized Microservices Configuration Script
# This script applies consistent coding standards and configurations to all microservices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        print_error "Directory $1 does not exist"
        exit 1
    fi
}

# Function to copy file with backup
copy_file_with_backup() {
    local source="$1"
    local destination="$2"
    local backup_dir="$3"
    
    if [ -f "$destination" ]; then
        mkdir -p "$backup_dir"
        cp "$destination" "$backup_dir/$(basename "$destination").backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Backed up existing file: $destination"
    fi
    
    cp "$source" "$destination"
    print_success "Copied $source to $destination"
}

# Function to create directory if it doesn't exist
create_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        print_success "Created directory: $1"
    fi
}

# Function to apply standards to a service
apply_standards_to_service() {
    local service_name="$1"
    local service_path="services/$service_name"
    
    print_status "Applying standards to $service_name..."
    
    # Check if service directory exists
    check_directory "$service_path"
    
    # Create backup directory
    local backup_dir="$service_path/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Copy standardized configuration files
    copy_file_with_backup "services/.rubocop.yml" "$service_path/.rubocop.yml" "$backup_dir"
    copy_file_with_backup "services/gemfile_template.rb" "$service_path/Gemfile" "$backup_dir"
    copy_file_with_backup "services/routes_template.rb" "$service_path/config/routes.rb" "$backup_dir"
    
    # Create standardized directory structure
    create_directory "$service_path/app/controllers/api/v1"
    create_directory "$service_path/app/models"
    create_directory "$service_path/app/serializers"
    create_directory "$service_path/app/services"
    create_directory "$service_path/app/validators"
    create_directory "$service_path/spec/controllers"
    create_directory "$service_path/spec/models"
    create_directory "$service_path/spec/services"
    create_directory "$service_path/spec/requests"
    
    # Copy base classes
    copy_file_with_backup "services/base_application_controller.rb" "$service_path/app/controllers/application_controller.rb" "$backup_dir"
    copy_file_with_backup "services/base_model.rb" "$service_path/app/models/base_model.rb" "$backup_dir"
    copy_file_with_backup "services/api_controller_template.rb" "$service_path/app/controllers/api/v1/base_controller.rb" "$backup_dir"
    
    # Create standardized initializers
    create_directory "$service_path/config/initializers"
    
    # Create CORS initializer
    cat > "$service_path/config/initializers/cors.rb" << 'EOF'
# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: false
  end
end
EOF
    
    # Create JWT initializer
    cat > "$service_path/config/initializers/jwt.rb" << 'EOF'
# frozen_string_literal: true

JWT_SECRET_KEY = ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
EOF
    
    # Create logging initializer
    cat > "$service_path/config/initializers/logging.rb" << 'EOF'
# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    {
      time: event.time,
      remote_ip: event.payload[:remote_ip],
      user_id: event.payload[:user_id],
      params: event.payload[:params].except(*Rails.application.config.filter_parameters),
      exception: event.payload[:exception]&.first,
      exception_message: event.payload[:exception]&.last
    }
  end
end
EOF
    
    # Create RSpec configuration
    if [ ! -f "$service_path/spec/spec_helper.rb" ]; then
        cat > "$service_path/spec/spec_helper.rb" << 'EOF'
# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_path = Rails.root.join('spec/fixtures')
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  
  config.include FactoryBot::Syntax::Methods
  config.include Shoulda::Matchers::ActiveRecord, type: :model
  config.include Shoulda::Matchers::ActiveModel, type: :model
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
EOF
    fi
    
    # Create FactoryBot configuration
    if [ ! -f "$service_path/spec/factories.rb" ]; then
        cat > "$service_path/spec/factories.rb" << 'EOF'
# frozen_string_literal: true

FactoryBot.define do
  # Define your factories here
  # Example:
  # factory :user do
  #   email { Faker::Internet.email }
  #   password { 'password123' }
  #   status { 'active' }
  # end
end
EOF
    fi
    
    # Create README template
    if [ ! -f "$service_path/README.md" ]; then
        cat > "$service_path/README.md" << EOF
# $service_name Service

## Description
Brief description of the service and its responsibilities.

## Setup
\`\`\`bash
bundle install
rails db:create db:migrate
rails server
\`\`\`

## API Endpoints
Document your API endpoints here.

## Testing
\`\`\`bash
rspec
\`\`\`

## Code Standards
This service follows the standardized coding practices defined in \`CODING_STANDARDS.md\`.
EOF
    fi
    
    print_success "Completed applying standards to $service_name"
}

# Function to validate service structure
validate_service_structure() {
    local service_name="$1"
    local service_path="services/$service_name"
    
    print_status "Validating structure for $service_name..."
    
    # Check required files
    local required_files=(
        "app/controllers/application_controller.rb"
        "app/models/base_model.rb"
        "app/controllers/api/v1/base_controller.rb"
        "config/routes.rb"
        "Gemfile"
        ".rubocop.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$service_path/$file" ]; then
            print_error "Missing required file: $service_path/$file"
            return 1
        fi
    done
    
    # Check required directories
    local required_dirs=(
        "app/controllers/api/v1"
        "app/models"
        "app/serializers"
        "app/services"
        "spec/controllers"
        "spec/models"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$service_path/$dir" ]; then
            print_error "Missing required directory: $service_path/$dir"
            return 1
        fi
    done
    
    print_success "Structure validation passed for $service_name"
    return 0
}

# Function to run RuboCop check
run_rubocop_check() {
    local service_name="$1"
    local service_path="services/$service_name"
    
    print_status "Running RuboCop check for $service_name..."
    
    cd "$service_path"
    
    if bundle exec rubocop --format progress; then
        print_success "RuboCop check passed for $service_name"
    else
        print_warning "RuboCop found issues in $service_name"
        print_status "Run 'bundle exec rubocop -a' to auto-fix issues"
    fi
    
    cd - > /dev/null
}

# Main execution
main() {
    print_status "Starting standardized configuration application..."
    
    # Check if we're in the correct directory
    if [ ! -d "services" ]; then
        print_error "This script must be run from the shopping_cart root directory"
        exit 1
    fi
    
    # Get list of services
    local services=($(ls -d services/*/ | sed 's/services\///' | sed 's/\///'))
    
    if [ ${#services[@]} -eq 0 ]; then
        print_error "No services found in services directory"
        exit 1
    fi
    
    print_status "Found ${#services[@]} services: ${services[*]}"
    
    # Apply standards to each service
    for service in "${services[@]}"; do
        if [ "$service" != "api-gateway-backup" ]; then
            apply_standards_to_service "$service"
        fi
    done
    
    # Validate all services
    print_status "Validating all services..."
    local validation_failed=false
    
    for service in "${services[@]}"; do
        if [ "$service" != "api-gateway-backup" ]; then
            if ! validate_service_structure "$service"; then
                validation_failed=true
            fi
        fi
    done
    
    if [ "$validation_failed" = true ]; then
        print_error "Some services failed validation. Please check the errors above."
        exit 1
    fi
    
    # Run RuboCop checks
    print_status "Running RuboCop checks..."
    for service in "${services[@]}"; do
        if [ "$service" != "api-gateway-backup" ]; then
            run_rubocop_check "$service"
        fi
    done
    
    print_success "Standardized configuration application completed!"
    print_status "Next steps:"
    print_status "1. Review the backup files in each service's backup directory"
    print_status "2. Run 'bundle install' in each service directory"
    print_status "3. Fix any RuboCop violations"
    print_status "4. Update service-specific code to inherit from base classes"
    print_status "5. Run tests to ensure everything works correctly"
}

# Run main function
main "$@"
