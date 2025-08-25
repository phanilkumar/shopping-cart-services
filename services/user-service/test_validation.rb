#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

BASE_URL = 'http://localhost:3001'

def get_csrf_token
  uri = URI("#{BASE_URL}/register")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri)
  
  response = http.request(request)
  
  # Extract CSRF token from the response
  if response.body =~ /name="authenticity_token" value="([^"]+)"/
    return $1
  end
  
  nil
end

def test_validation_scenarios
  puts "🧪 Testing User Registration Validation Rules"
  puts "=" * 60
  
  # Get CSRF token
  csrf_token = get_csrf_token
  if csrf_token.nil?
    puts "❌ ERROR: Could not get CSRF token"
    return
  end
  puts "🔑 CSRF Token obtained: #{csrf_token[0..10]}..."
  
  # Test 1: Valid registration data
  puts "\n✅ Test 1: Valid Registration Data"
  valid_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "9876543210",
      password: "Password123!",
      password_confirmation: "Password123!"
    },
    terms: "on"
  }
  test_registration(valid_data, "Should succeed with valid data")
  
  # Test 2: Invalid email format
  puts "\n❌ Test 2: Invalid Email Format"
  invalid_email_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "invalid-email",
      phone: "9876543210",
      password: "Password123!",
      password_confirmation: "Password123!"
    },
    terms: "on"
  }
  test_registration(invalid_email_data, "Should fail with invalid email")
  
  # Test 3: Invalid phone number (not starting with 6,7,8,9)
  puts "\n❌ Test 3: Invalid Phone Number"
  invalid_phone_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe2@example.com",
      phone: "1234567890",
      password: "Password123!",
      password_confirmation: "Password123!"
    },
    terms: "on"
  }
  test_registration(invalid_phone_data, "Should fail with invalid phone number")
  
  # Test 4: Invalid first name (too short)
  puts "\n❌ Test 4: Invalid First Name (Too Short)"
  invalid_first_name_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "Jon", # Less than 4 characters
      last_name: "Doe",
      email: "john.doe3@example.com",
      phone: "9876543210",
      password: "Password123!",
      password_confirmation: "Password123!"
    },
    terms: "on"
  }
  test_registration(invalid_first_name_data, "Should fail with short first name")
  
  # Test 5: Invalid last name (contains numbers)
  puts "\n❌ Test 5: Invalid Last Name (Contains Numbers)"
  invalid_last_name_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe123",
      email: "john.doe4@example.com",
      phone: "9876543210",
      password: "Password123!",
      password_confirmation: "Password123!"
    },
    terms: "on"
  }
  test_registration(invalid_last_name_data, "Should fail with invalid last name")
  
  # Test 5a: Invalid first name (contains spaces)
  puts "\n❌ Test 5a: Invalid First Name (Contains Spaces)"
  invalid_first_name_space_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "Mary Jane", # Contains space
      last_name: "Doe",
      email: "john.doe4a@example.com",
      phone: "9876543210",
      password: "Password123!",
      password_confirmation: "Password123!"
    },
    terms: "on"
  }
  test_registration(invalid_first_name_space_data, "Should fail with first name containing spaces")
  
  # Test 5b: Invalid last name (contains hyphens)
  puts "\n❌ Test 5b: Invalid Last Name (Contains Hyphens)"
  invalid_last_name_hyphen_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Jean-Pierre", # Contains hyphen
      email: "john.doe4b@example.com",
      phone: "9876543210",
      password: "Password123!",
      password_confirmation: "Password123!"
    },
    terms: "on"
  }
  test_registration(invalid_last_name_hyphen_data, "Should fail with last name containing hyphens")
  
  # Test 6: Password too short
  puts "\n❌ Test 6: Password Too Short"
  short_password_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe5@example.com",
      phone: "9876543210",
      password: "Pass1!",
      password_confirmation: "Pass1!"
    },
    terms: "on"
  }
  test_registration(short_password_data, "Should fail with short password")
  
  # Test 7: Password too long
  puts "\n❌ Test 7: Password Too Long"
  long_password_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe6@example.com",
      phone: "9876543210",
      password: "Password123!@#$%^&*()_+-=[]{}|;:,.<>?",
      password_confirmation: "Password123!@#$%^&*()_+-=[]{}|;:,.<>?"
    },
    terms: "on"
  }
  test_registration(long_password_data, "Should fail with long password")
  
  # Test 8: Password without letters
  puts "\n❌ Test 8: Password Without Letters"
  no_letters_password_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe7@example.com",
      phone: "9876543210",
      password: "12345678!",
      password_confirmation: "12345678!"
    },
    terms: "on"
  }
  test_registration(no_letters_password_data, "Should fail with password without letters")
  
  # Test 9: Password without numbers
  puts "\n❌ Test 9: Password Without Numbers"
  no_numbers_password_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe8@example.com",
      phone: "9876543210",
      password: "Password!",
      password_confirmation: "Password!"
    },
    terms: "on"
  }
  test_registration(no_numbers_password_data, "Should fail with password without numbers")
  
  # Test 10: Password without special characters
  puts "\n❌ Test 10: Password Without Special Characters"
  no_special_password_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe9@example.com",
      phone: "9876543210",
      password: "Password123",
      password_confirmation: "Password123"
    },
    terms: "on"
  }
  test_registration(no_special_password_data, "Should fail with password without special characters")
  
  # Test 11: Password confirmation mismatch
  puts "\n❌ Test 11: Password Confirmation Mismatch"
  password_mismatch_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe10@example.com",
      phone: "9876543210",
      password: "Password123!",
      password_confirmation: "DifferentPassword123!"
    },
    terms: "on"
  }
  test_registration(password_mismatch_data, "Should fail with password confirmation mismatch")
  
  # Test 12: Duplicate email
  puts "\n❌ Test 12: Duplicate Email"
  duplicate_email_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "admin@example.com", # This email already exists
      phone: "9876543210",
      password: "Password123!",
      password_confirmation: "Password123!"
    },
    terms: "on"
  }
  test_registration(duplicate_email_data, "Should fail with duplicate email")
  
  # Test 13: Duplicate phone
  puts "\n❌ Test 13: Duplicate Phone"
  duplicate_phone_data = {
    authenticity_token: csrf_token,
    user: {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe11@example.com",
      phone: "9876543210", # This phone already exists
      password: "Password123!",
      password_confirmation: "Password123!"
    },
    terms: "on"
  }
  test_registration(duplicate_phone_data, "Should fail with duplicate phone")
  
  puts "\n" + "=" * 60
  puts "🎉 Validation Testing Complete!"
end

def test_registration(data, description)
  puts "  #{description}..."
  
  uri = URI("#{BASE_URL}/register")
  http = Net::HTTP.new(uri.host, uri.port)
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/x-www-form-urlencoded'
  
  # Convert data to form-encoded format
  form_data = []
  data.each do |key, value|
    if value.is_a?(Hash)
      value.each do |sub_key, sub_value|
        form_data << "#{key}[#{sub_key}]=#{URI.encode_www_form_component(sub_value.to_s)}"
      end
    else
      form_data << "#{key}=#{URI.encode_www_form_component(value.to_s)}"
    end
  end
  request.body = form_data.join('&')
  
  begin
    response = http.request(request)
    
    if response.code == '302' && response['location']&.include?('congratulations')
      puts "    ✅ SUCCESS: Registration successful"
    elsif response.code == '200'
      puts "    ❌ FAILED: Registration failed (expected validation errors)"
      # Check if there are validation errors in the response
      if response.body.include?('error') || response.body.include?('invalid')
        puts "    ✅ VALIDATION: Proper validation errors detected"
      else
        puts "    ⚠️  WARNING: No clear validation errors found"
      end
    elsif response.code == '422'
      puts "    ✅ VALIDATION: Form validation failed (422 status)"
      # Check for specific validation messages
      body = response.body
      if body.include?('error') || body.include?('invalid') || body.include?('must') || body.include?('required')
        puts "    ✅ VALIDATION: Validation errors detected in response"
      else
        puts "    ⚠️  WARNING: 422 response but no clear validation messages"
      end
    else
      puts "    ❓ UNEXPECTED: Response code #{response.code}"
    end
  rescue => e
    puts "    ❌ ERROR: #{e.message}"
  end
end

# Run the tests
if __FILE__ == $0
  test_validation_scenarios
end
