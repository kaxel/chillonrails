FactoryBot.define do
  factory :submission do
    contact_name { "Jane Doe" }
    email { "jane@example.com" }
    artist_name { "The Janes" }
    status { "pending" }

    # A valid submission always has at least one song, so build one by default.
    after(:build) do |submission|
      submission.submission_songs << build(:submission_song, submission: submission) if submission.submission_songs.empty?
    end

    trait :paid do
      status { "paid" }
    end
  end
end
