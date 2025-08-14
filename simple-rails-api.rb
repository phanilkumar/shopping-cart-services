#!/usr/bin/env ruby

require 'sinatra'
require 'json'
require 'jwt'
require 'bcrypt'

# Enable CORS manually
before do
  headers['Access-Control-Allow-Origin'] = '*'
  headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  headers['Access-Control-Allow-Credentials'] = 'true'
end

# Handle preflight requests
options '*' do
  response.headers["Allow"] = "GET, POST, PUT, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
  200
end

# Mock data for testing
USERS = [
  {
    id: 1,
    email: 'admin@ecommerce.com',
    first_name: 'Admin',
    last_name: 'User',
    role: 'admin',
    avatar_url: 'https://via.placeholder.com/150/1976d2/ffffff?text=A',
    is_active: true,
    created_at: '2024-01-01T00:00:00Z'
  },
  {
    id: 2,
    email: 'john.doe@example.com',
    first_name: 'John',
    last_name: 'Doe',
    role: 'customer',
    avatar_url: 'https://via.placeholder.com/150/4caf50/ffffff?text=J',
    is_active: true,
    created_at: '2024-01-15T00:00:00Z'
  }
]

PRODUCTS = [
  {
    id: 1,
    name: 'iPhone 13 Pro',
    description: 'Latest iPhone with advanced camera system and A15 Bionic chip',
    price: 999.99,
    sale_price: 899.99,
    category: 'Electronics',
    stock_quantity: 50,
    is_featured: true,
    image_url: 'https://via.placeholder.com/400x400/1976d2/ffffff?text=iPhone'
  },
  {
    id: 2,
    name: 'Samsung Galaxy S21',
    description: 'Premium Android smartphone with 8K video recording',
    price: 799.99,
    sale_price: 699.99,
    category: 'Electronics',
    stock_quantity: 35,
    is_featured: true,
    image_url: 'https://via.placeholder.com/400x400/4caf50/ffffff?text=Samsung'
  }
]

ORDERS = [
  {
    id: 1,
    order_number: 'ORD-2024-001',
    status: 'delivered',
    total_amount: 1049.98,
    user_id: 2,
    created_at: '2024-01-15T00:00:00Z'
  },
  {
    id: 2,
    order_number: 'ORD-2024-002',
    status: 'shipped',
    total_amount: 169.98,
    user_id: 2,
    created_at: '2024-01-20T00:00:00Z'
  }
]

# JWT Secret (in production, use a secure secret)
JWT_SECRET = 'your-secret-key-here'

# Helper method to generate JWT token
def generate_token(user)
  payload = {
    user_id: user[:id],
    email: user[:email],
    role: user[:role],
    exp: Time.now.to_i + (24 * 60 * 60) # 24 hours
  }
  JWT.encode(payload, JWT_SECRET, 'HS256')
end

# Helper method to verify JWT token
def verify_token(token)
  decoded = JWT.decode(token, JWT_SECRET, true, { algorithm: 'HS256' })
  decoded[0]
rescue JWT::DecodeError
  nil
end

# Helper method to get current user from request
def current_user
  auth_header = request.env['HTTP_AUTHORIZATION']
  return nil unless auth_header && auth_header.start_with?('Bearer ')
  
  token = auth_header.split(' ')[1]
  payload = verify_token(token)
  return nil unless payload
  
  USERS.find { |user| user[:id] == payload['user_id'] }
end

# Health check endpoint
get '/health' do
  content_type :json
  { status: 'ok', timestamp: Time.now.iso8601 }.to_json
end

# Authentication endpoints
post '/api/v1/auth/login' do
  content_type :json
  
  data = JSON.parse(request.body.read)
  email = data['email']
  password = data['password']
  
  # Simple authentication (in production, use proper password hashing)
  user = USERS.find { |u| u[:email] == email }
  
  if user && password == 'password123'
    token = generate_token(user)
    {
      user: user,
      token: token,
      message: 'Login successful'
    }.to_json
  else
    status 401
    { error: 'Invalid credentials' }.to_json
  end
end

# Admin dashboard endpoints
get '/api/v1/admin/dashboard' do
  content_type :json
  
  user = current_user
  return status 401 unless user && user[:role] == 'admin'
  
  {
    stats: {
      total_revenue: 124563,
      total_orders: 1234,
      total_users: 8456,
      total_products: 156
    },
    recent_orders: ORDERS.first(5),
    recent_users: USERS.first(5),
    chart_data: {
      sales: [
        { name: 'Jan', sales: 4000 },
        { name: 'Feb', sales: 3000 },
        { name: 'Mar', sales: 2000 },
        { name: 'Apr', sales: 2780 },
        { name: 'May', sales: 1890 },
        { name: 'Jun', sales: 2390 }
      ]
    }
  }.to_json
end

get '/api/v1/admin/users' do
  content_type :json
  
  user = current_user
  return status 401 unless user && user[:role] == 'admin'
  
  USERS.to_json
end

get '/api/v1/admin/products' do
  content_type :json
  
  user = current_user
  return status 401 unless user && user[:role] == 'admin'
  
  PRODUCTS.to_json
end

get '/api/v1/admin/orders' do
  content_type :json
  
  user = current_user
  return status 401 unless user && user[:role] == 'admin'
  
  ORDERS.to_json
end

# Public endpoints (for testing)
get '/api/v1/users' do
  content_type :json
  USERS.to_json
end

get '/api/v1/products' do
  content_type :json
  PRODUCTS.to_json
end

get '/api/v1/orders' do
  content_type :json
  ORDERS.to_json
end

# Root endpoint
get '/' do
  content_type :json
  {
    message: 'E-commerce API Server',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      auth: '/api/v1/auth/login',
      admin: {
        dashboard: '/api/v1/admin/dashboard',
        users: '/api/v1/admin/users',
        products: '/api/v1/admin/products',
        orders: '/api/v1/admin/orders'
      },
      public: {
        users: '/api/v1/users',
        products: '/api/v1/products',
        orders: '/api/v1/orders'
      }
    }
  }.to_json
end

# Start the server
if __FILE__ == $0
  port = ENV['PORT'] || 3000
  puts "🚀 Starting Simple Rails API Server on port #{port}"
  puts "📊 Health check: http://localhost:#{port}/health"
  puts "🔗 API docs: http://localhost:#{port}/"
  puts "🔑 Test login: admin@ecommerce.com / password123"
  
  Sinatra::Application.run!(
    port: port,
    bind: '0.0.0.0',
    environment: :development
  )
end
