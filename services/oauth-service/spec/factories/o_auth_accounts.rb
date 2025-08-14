FactoryBot.define do
  factory :o_auth_account do
    user { nil }
    provider { "MyString" }
    provider_uid { "MyString" }
    access_token { "MyText" }
    refresh_token { "MyText" }
    expires_at { "2025-08-14 22:56:29" }
  end
end
