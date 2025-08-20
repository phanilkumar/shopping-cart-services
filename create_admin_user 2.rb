#!/usr/bin/env ruby

# Script to create an admin user in the user-service
require 'bundler/setup'

# Create admin user
admin_user = User.create!(
  email: 'admin@example.com',
  first_name: 'Admin',
  last_name: 'User',
  phone: '+919876543210',
  password: 'admin123',
  password_confirmation: 'admin123',
  role: 1,  # Assuming 1 is admin role
  status: 1, # Assuming 1 is active status
  email_verified_at: Time.current
)

puts "Admin user created successfully!"
puts "Email: #{admin_user.email}"
puts "Name: #{admin_user.first_name} #{admin_user.last_name}"
puts "Phone: #{admin_user.phone}"
puts "Role: #{admin_user.role}"
puts "Status: #{admin_user.status}"
