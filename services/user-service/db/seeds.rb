# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database with test data..."

# Clear existing data (optional - uncomment if you want to start fresh)
# User.destroy_all
# JwtDenylist.destroy_all

# Create admin users
admin_user = User.find_or_create_by(email: 'admin@example.com') do |user|
  user.first_name = 'Admin'
  user.last_name = 'User'
  user.phone = '+919876543210'
  user.password = 'admin123'
  user.password_confirmation = 'admin123'
  user.role = 1  # admin
  user.status = 1  # active
end

super_admin = User.find_or_create_by(email: 'superadmin@example.com') do |user|
  user.first_name = 'Super'
  user.last_name = 'Admin'
  user.phone = '+919876543211'
  user.password = 'superadmin123'
  user.password_confirmation = 'superadmin123'
  user.role = 1  # admin
  user.status = 1  # active
end

# Create regular users
regular_user1 = User.find_or_create_by(email: 'john.doe@example.com') do |user|
  user.first_name = 'John'
  user.last_name = 'Doe'
  user.phone = '+919876543212'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0  # regular user
  user.status = 1  # active
end

regular_user2 = User.find_or_create_by(email: 'jane.smith@example.com') do |user|
  user.first_name = 'Jane'
  user.last_name = 'Smith'
  user.phone = '+919876543213'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0  # regular user
  user.status = 1  # active
end

regular_user3 = User.find_or_create_by(email: 'mike.wilson@example.com') do |user|
  user.first_name = 'Mike'
  user.last_name = 'Wilson'
  user.phone = '+919876543214'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0  # regular user
  user.status = 1  # active
end

# Create inactive users for testing
inactive_user = User.find_or_create_by(email: 'inactive@example.com') do |user|
  user.first_name = 'Inactive'
  user.last_name = 'User'
  user.phone = '+919876543215'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0  # regular user
  user.status = 0  # inactive
end

# Create users with different phone formats for testing
user_with_10_digit = User.find_or_create_by(email: 'test10digit@example.com') do |user|
  user.first_name = 'Test'
  user.last_name = 'TenDigit'
  user.phone = '9876543216'  # Will be automatically formatted to +919876543216
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0
  user.status = 1
end

user_with_91_prefix = User.find_or_create_by(email: 'test91prefix@example.com') do |user|
  user.first_name = 'Test'
  user.last_name = 'NinetyOne'
  user.phone = '919876543217'  # Will be automatically formatted to +919876543217
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0
  user.status = 1
end

# Create users for OTP testing
otp_test_user = User.find_or_create_by(email: 'otptest@example.com') do |user|
  user.first_name = 'OTP'
  user.last_name = 'Test'
  user.phone = '+919876543218'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0
  user.status = 1
end

# Create users for API testing
api_test_user = User.find_or_create_by(email: 'apitest@example.com') do |user|
  user.first_name = 'API'
  user.last_name = 'Test'
  user.phone = '+919876543219'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0
  user.status = 1
end

# Create users with minimal data for edge case testing
minimal_user = User.find_or_create_by(email: 'minimal@example.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0
  user.status = 1
end

# Create users for different scenarios
user_without_phone = User.find_or_create_by(email: 'nophone@example.com') do |user|
  user.first_name = 'No'
  user.last_name = 'Phone'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 0
  user.status = 1
end

# Update last login times for some users to simulate activity
admin_user.update(last_login_at: 1.hour.ago)
regular_user1.update(last_login_at: 2.hours.ago)
regular_user2.update(last_login_at: 1.day.ago)

puts "Seed data created successfully!"
puts "Created #{User.count} users:"
puts "- #{User.where(role: 1).count} admin users"
puts "- #{User.where(role: 0).count} regular users"
puts "- #{User.where(status: 1).count} active users"
puts "- #{User.where(status: 0).count} inactive users"

puts "\nTest credentials:"
puts "Admin: admin@example.com / admin123"
puts "Super Admin: superadmin@example.com / superadmin123"
puts "Regular User: john.doe@example.com / password123"
puts "OTP Test: otptest@example.com / password123"
puts "API Test: apitest@example.com / password123"
puts "Inactive User: inactive@example.com / password123"
