FactoryBot.define do
  factory :user do
    email { "MyString" }
    first_name { "MyString" }
    last_name { "MyString" }
    phone { "MyString" }
    status { 1 }
    role { 1 }
    last_login_at { "2025-08-14 22:47:40" }
    email_verified_at { "2025-08-14 22:47:40" }
    password_reset_token { "MyString" }
    password_reset_sent_at { "2025-08-14 22:47:40" }
  end
end
