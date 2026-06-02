FactoryBot.define do
  factory :playlist do
    sequence(:name) { |n| "Playlist #{n}" }
    sequence(:slug) { |n| "playlist-#{n}" }
    songs { {} }
  end
end
