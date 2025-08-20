#!/usr/bin/env ruby

# Create a minimal User model that works with the current schema
minimal_user_model = <<~RUBY
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Basic validations only
  validates :email, presence: true, uniqueness: true
  validates :phone, presence: true, if: :phone_required?

  # Instance methods
  def display_name
    [first_name, last_name].compact.join(' ').presence || email
  end

  def phone_required?
    email.blank?
  end
end
RUBY

# Write the minimal model
File.write('/rails/app/models/user.rb', minimal_user_model)
puts "✅ Minimal User model created successfully!"
