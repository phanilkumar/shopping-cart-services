# frozen_string_literal: true

FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-08-24 11:08:13" }
  end

  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone { "+91#{Faker::Number.number(digits: 10)}" }
    status { 'active' }
    role { 'user' }
  end

  factory :admin_user, parent: :user do
    role { 'admin' }
  end

  factory :moderator_user, parent: :user do
    role { 'moderator' }
  end

  factory :inactive_user, parent: :user do
    status { 'inactive' }
  end
end




