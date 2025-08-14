FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-08-14 22:48:00" }
  end
end
