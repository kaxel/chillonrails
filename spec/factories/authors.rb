FactoryBot.define do
  factory :author do
    sequence(:name) { |n| "Author #{n}" }
    sequence(:slug) { |n| "author-#{n}" }
    draft { false }
    location { "los-angeles" }
  end
end
