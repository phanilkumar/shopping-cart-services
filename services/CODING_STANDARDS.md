# Microservices Coding Standards & Best Practices

## Table of Contents
1. [General Principles](#general-principles)
2. [File Structure](#file-structure)
3. [Naming Conventions](#naming-conventions)
4. [Code Style](#code-style)
5. [Controllers](#controllers)
6. [Models](#models)
7. [API Design](#api-design)
8. [Error Handling](#error-handling)
9. [Testing](#testing)
10. [Security](#security)
11. [Performance](#performance)
12. [Documentation](#documentation)

## General Principles

### 1. Consistency
- All microservices must follow identical patterns and conventions
- No deviations from established standards are allowed
- Use shared base classes and templates

### 2. Single Responsibility
- Each service has one clear purpose
- Each class has one responsibility
- Each method does one thing well

### 3. DRY (Don't Repeat Yourself)
- Extract common functionality into base classes
- Use shared utilities and helpers
- Avoid code duplication across services

### 4. SOLID Principles
- **S**: Single Responsibility Principle
- **O**: Open/Closed Principle
- **L**: Liskov Substitution Principle
- **I**: Interface Segregation Principle
- **D**: Dependency Inversion Principle

## File Structure

### Standard Directory Structure
```
service-name/
├── app/
│   ├── controllers/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── base_controller.rb
│   │   │       ├── auth_controller.rb
│   │   │       └── [resource]_controller.rb
│   │   └── application_controller.rb
│   ├── models/
│   │   ├── base_model.rb
│   │   └── [resource].rb
│   ├── serializers/
│   │   └── [resource]_serializer.rb
│   ├── services/
│   │   └── [service_name].rb
│   └── validators/
│       └── [validator_name].rb
├── config/
│   ├── routes.rb
│   ├── application.rb
│   └── initializers/
├── db/
│   ├── migrate/
│   └── seeds/
├── spec/
│   ├── controllers/
│   ├── models/
│   ├── services/
│   └── requests/
├── lib/
├── Gemfile
├── .rubocop.yml
└── README.md
```

## Naming Conventions

### 1. Files and Directories
- Use snake_case for file and directory names
- Use descriptive, meaningful names
- Group related files in appropriate directories

### 2. Classes and Modules
- Use PascalCase for class and module names
- Use descriptive names that indicate purpose
- Prefix with service name for clarity

### 3. Methods and Variables
- Use snake_case for method and variable names
- Use descriptive, action-oriented names for methods
- Use clear, meaningful names for variables

### 4. Constants
- Use SCREAMING_SNAKE_CASE for constants
- Define constants at the top of classes
- Use frozen_string_literal: true

## Code Style

### 1. Ruby Style Guide
- Follow the Ruby Style Guide
- Use RuboCop for automated style checking
- Maximum line length: 120 characters
- Use 2 spaces for indentation

### 2. Method Length
- Keep methods under 20 lines
- Extract complex logic into private methods
- Use guard clauses for early returns

### 3. Class Length
- Keep classes under 200 lines
- Extract complex functionality into separate classes
- Use composition over inheritance

### 4. Comments
- Write self-documenting code
- Use comments only when necessary
- Document complex business logic
- Use YARD-style documentation for public APIs

## Controllers

### 1. Inheritance
```ruby
class Api::V1::ResourceController < Api::V1::BaseController
  # All controllers must inherit from BaseController
end
```

### 2. Standard Actions
```ruby
class Api::V1::ResourceController < Api::V1::BaseController
  def index
    resources = Resource.all
    index_action(resources, allowed_filters: [:status, :category])
  end

  def show
    resource = Resource.find(params[:id])
    show_action(resource)
  end

  def create
    create_action(Resource, :resource_params, ResourceSerializer)
  end

  def update
    resource = Resource.find(params[:id])
    update_action(resource, :resource_params, ResourceSerializer)
  end

  def destroy
    resource = Resource.find(params[:id])
    destroy_action(resource)
  end

  private

  def resource_params
    params.require(:resource).permit(:name, :description, :status)
  end
end
```

### 3. Authorization
```ruby
# Always check authorization before actions
before_action :authorize_user!
before_action :authorize_admin!, only: [:destroy]
before_action :authorize_owner!, only: [:update, :destroy]
```

## Models

### 1. Inheritance
```ruby
class Resource < BaseModel
  # All models must inherit from BaseModel
end
```

### 2. Validations
```ruby
class Resource < BaseModel
  validates :name, presence: { message: VALIDATION_MESSAGES[:required] }
  validates :email, uniqueness: { message: VALIDATION_MESSAGES[:already_exists] }
  validates :status, inclusion: { in: valid_statuses }
end
```

### 3. Associations
```ruby
class Resource < BaseModel
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_one :profile
end
```

### 4. Scopes
```ruby
class Resource < BaseModel
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :search, ->(query) { where("name ILIKE ?", "%#{query}%") }
end
```

## API Design

### 1. Response Format
```json
{
  "status": "success|error",
  "message": "Human readable message",
  "data": {},
  "errors": [],
  "meta": {
    "pagination": {},
    "timestamp": "2023-01-01T00:00:00Z",
    "request_id": "uuid"
  }
}
```

### 2. HTTP Status Codes
- 200: OK
- 201: Created
- 204: No Content
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 422: Unprocessable Entity
- 500: Internal Server Error

### 3. URL Structure
```
GET    /api/v1/resources
GET    /api/v1/resources/:id
POST   /api/v1/resources
PUT    /api/v1/resources/:id
PATCH  /api/v1/resources/:id
DELETE /api/v1/resources/:id
```

### 4. Query Parameters
```
GET /api/v1/resources?page=1&per_page=20&sort=created_at&direction=desc&q=search&status=active
```

## Error Handling

### 1. Standard Error Responses
```ruby
# Use standardized error responses
error_response('Validation failed', errors, :unprocessable_entity)
format_not_found_error('Resource')
format_unauthorized_error('Authentication required')
format_forbidden_error('Access denied')
```

### 2. Exception Handling
```ruby
# Use rescue_from for consistent error handling
rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
rescue_from StandardError, with: :handle_standard_error
```

### 3. Validation Errors
```ruby
# Always return detailed validation errors
def handle_validation_error(exception)
  error_response(
    'Validation failed',
    exception.record.errors.full_messages,
    :unprocessable_entity
  )
end
```

## Testing

### 1. Test Structure
```ruby
RSpec.describe Api::V1::ResourceController, type: :controller do
  describe 'GET #index' do
    context 'when user is authenticated' do
      it 'returns list of resources' do
        # Test implementation
      end
    end
  end
end
```

### 2. Test Coverage
- Minimum 90% test coverage
- Test all public methods
- Test error scenarios
- Test edge cases

### 3. Test Data
```ruby
# Use FactoryBot for test data
FactoryBot.define do
  factory :resource do
    name { Faker::Company.name }
    description { Faker::Lorem.sentence }
    status { 'active' }
    association :user
  end
end
```

## Security

### 1. Authentication
- Use JWT tokens for API authentication
- Implement token refresh mechanism
- Validate tokens on every request

### 2. Authorization
- Check user permissions before actions
- Use role-based access control
- Implement resource ownership checks

### 3. Input Validation
- Validate all input parameters
- Sanitize user input
- Use strong parameters

### 4. SQL Injection Prevention
- Use parameterized queries
- Avoid raw SQL when possible
- Validate and sanitize inputs

## Performance

### 1. Database Optimization
- Use proper indexes
- Avoid N+1 queries
- Use eager loading for associations

### 2. Caching
- Cache frequently accessed data
- Use Redis for caching
- Implement cache invalidation

### 3. Pagination
- Always paginate large collections
- Limit maximum page size
- Use cursor-based pagination for large datasets

## Documentation

### 1. API Documentation
- Use OpenAPI/Swagger for API documentation
- Document all endpoints
- Include request/response examples

### 2. Code Documentation
- Document complex business logic
- Use YARD-style comments for public methods
- Keep documentation up to date

### 3. README Files
- Include setup instructions
- Document API endpoints
- Include testing instructions

## Enforcement

### 1. Automated Checks
- RuboCop for code style
- Brakeman for security
- Bullet for N+1 queries
- SimpleCov for test coverage

### 2. Code Reviews
- All code must be reviewed
- Check for adherence to standards
- Verify test coverage

### 3. Continuous Integration
- Run all checks on every commit
- Fail builds on violations
- Generate reports for violations

## Compliance Checklist

Before merging any code, ensure:

- [ ] Code follows RuboCop standards
- [ ] All tests pass
- [ ] Test coverage is above 90%
- [ ] No security vulnerabilities (Brakeman)
- [ ] No N+1 queries (Bullet)
- [ ] API documentation is updated
- [ ] README is updated if needed
- [ ] Code is reviewed by team member
- [ ] All standards in this document are followed

## Violations

Any violation of these standards will result in:
1. Code review rejection
2. Required fixes before merge
3. Documentation of the violation
4. Team discussion to prevent future violations

**No exceptions or deviations are allowed.**
