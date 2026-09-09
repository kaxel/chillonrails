FactoryBot.define do
  factory :submission_song do
    sequence(:title) { |n| "Song #{n}" }
    submission

    after(:build) do |song|
      unless song.audio.attached?
        song.audio.attach(
          io: Rails.root.join("spec/fixtures/files/sample.mp3").open,
          filename: "sample.mp3",
          content_type: "audio/mpeg"
        )
      end
    end
  end
end
