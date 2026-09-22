FactoryBot.define do
  factory :page_not_found do
    url { "/missing-page" }
    accessed_at { Time.current }
  end
end
