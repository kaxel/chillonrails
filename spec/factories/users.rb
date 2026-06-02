FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :oauth do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "uid-#{n}" }
      password { nil }
      confirmed_at { Time.current }
    end
  end
end
