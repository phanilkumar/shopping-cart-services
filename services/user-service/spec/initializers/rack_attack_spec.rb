# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rack::Attack configuration' do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  before do
    # Clear cache before each test
    Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
  end

  describe 'rate limiting' do
    context 'login attempts' do
      it 'throttles after 5 attempts in development' do
        limit = Rails.env.development? ? 50 : 5
        
        limit.times do
          post '/users/sign_in', { user: { email: 'test@example.com', password: 'wrong' } }.to_json,
               'CONTENT_TYPE' => 'application/json'
          expect(last_response.status).not_to eq(429)
        end

        # One more should trigger rate limit
        post '/users/sign_in', { user: { email: 'test@example.com', password: 'wrong' } }.to_json,
             'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(429)
        
        response_body = JSON.parse(last_response.body)
        expect(response_body['error']).to eq('rate_limit_exceeded')
      end
    end

    context 'API requests' do
      it 'throttles general API requests' do
        limit = Rails.env.development? ? 1000 : 100
        
        limit.times do |i|
          get "/api/v1/users/#{i}"
          expect(last_response.status).not_to eq(429)
        end

        # One more should trigger rate limit
        get '/api/v1/users/999'
        expect(last_response.status).to eq(429)
      end
    end
  end

  describe 'security blocking' do
    context 'attack patterns' do
      it 'blocks SQL injection attempts' do
        skip 'Attack patterns disabled in development' if Rails.env.development? && ENV['ENABLE_ATTACK_PATTERNS'] != 'true'
        
        get '/api/v1/users?id=1 OR 1=1'
        expect(last_response.status).to eq(403)
        
        response_body = JSON.parse(last_response.body)
        expect(response_body['error']).to eq('forbidden')
      end

      it 'blocks XSS attempts' do
        skip 'Attack patterns disabled in development' if Rails.env.development? && ENV['ENABLE_ATTACK_PATTERNS'] != 'true'
        
        get '/api/v1/users?name=<script>alert(1)</script>'
        expect(last_response.status).to eq(403)
      end

      it 'blocks path traversal attempts' do
        skip 'Attack patterns disabled in development' if Rails.env.development? && ENV['ENABLE_ATTACK_PATTERNS'] != 'true'
        
        get '/api/v1/files?path=../../etc/passwd'
        expect(last_response.status).to eq(403)
      end
    end

    context 'suspicious user agents' do
      it 'blocks requests with bot user agents in production' do
        skip 'User agent blocking disabled in development' unless Rails.env.production?
        
        get '/', {}, 'HTTP_USER_AGENT' => 'sqlmap/1.0'
        expect(last_response.status).to eq(403)
      end

      it 'allows normal browser user agents' do
        get '/', {}, 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        expect(last_response.status).not_to eq(403)
      end
    end
  end

  describe 'safelisting' do
    it 'allows localhost in development' do
      skip 'Only applicable in development' unless Rails.env.development?
      
      # Make many requests from localhost
      200.times do
        get '/', {}, 'REMOTE_ADDR' => '127.0.0.1'
        expect(last_response.status).not_to eq(429)
      end
    end
  end

  describe 'response headers' do
    context 'when rate limited' do
      before do
        # Trigger rate limit
        limit = Rails.env.development? ? 1000 : 100
        (limit + 1).times { get '/api/v1/test' }
      end

      it 'includes proper rate limit headers' do
        expect(last_response.headers).to include('Retry-After')
        expect(last_response.headers).to include('X-RateLimit-Limit')
        expect(last_response.headers).to include('X-RateLimit-Remaining')
        expect(last_response.headers).to include('X-RateLimit-Reset')
      end

      it 'returns proper error response' do
        body = JSON.parse(last_response.body)
        expect(body).to include('error' => 'rate_limit_exceeded')
        expect(body).to include('retry_after')
      end
    end
  end

  describe 'monitoring' do
    it 'tracks rate limit events' do
      expect(Rails.logger).to receive(:warn).with(/Rack::Attack/)
      
      # Trigger a rate limit
      limit = Rails.env.development? ? 1000 : 100
      (limit + 1).times { get '/api/v1/test' }
    end
  end
end