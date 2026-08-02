require 'rails_helper'

RSpec.describe Submission, type: :model do
  it "builds a valid submission from the factory" do
    expect(build(:submission)).to be_valid
  end

  it "requires contact_name, email and artist_name" do
    submission = build(:submission, contact_name: nil, email: nil, artist_name: nil)
    expect(submission).not_to be_valid
    expect(submission.errors.attribute_names).to include(:contact_name, :email, :artist_name)
  end

  it "rejects an invalid email" do
    expect(build(:submission, email: "not-an-email")).not_to be_valid
  end

  it "requires at least one song" do
    submission = Submission.new(contact_name: "A", email: "a@b.com", artist_name: "B")
    expect(submission).not_to be_valid
    expect(submission.errors[:base].join).to match(/at least one song/i)
  end

  it "generates a unique token" do
    submission = create(:submission)
    expect(submission.token).to be_present
    expect(submission.to_param).to eq(submission.token)
  end

  it "prices at $3 per song" do
    submission = create(:submission)
    submission.submission_songs << build(:submission_song, submission: submission)
    submission.save!
    submission.recalculate_amount!
    expect(submission.song_count).to eq(2)
    expect(submission.amount_cents).to eq(600)
    expect(submission.amount_dollars).to eq(6.0)
  end

  it "marks a submission paid" do
    submission = create(:submission)
    expect { submission.mark_paid! }.to change(submission, :paid?).from(false).to(true)
  end
end
