require 'rails_helper'

RSpec.describe SubmissionSong, type: :model do
  let(:submission) { create(:submission) }

  it "is valid with a title and attached audio" do
    expect(build(:submission_song, submission: submission)).to be_valid
  end

  it "requires a title" do
    expect(build(:submission_song, submission: submission, title: nil)).not_to be_valid
  end

  it "requires an attached audio file" do
    song = build(:submission_song, submission: submission)
    song.audio.detach if song.audio.attached?
    song = SubmissionSong.new(submission: submission, title: "No file")
    expect(song).not_to be_valid
    expect(song.errors[:audio].join).to match(/uploaded/i)
  end
end
