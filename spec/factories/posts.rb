FactoryBot.define do
  factory :post do
    sequence(:title) { |n| "Post Title #{n}" }
    content { "Some post content." }
    topic { "music" }
  end
end
