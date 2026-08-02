require 'rails_helper'

RSpec.describe PurgePendingSubmissionsJob, type: :job do
  def backdate(submission, hours)
    submission.update_column(:created_at, hours.hours.ago)
    submission
  end

  it "destroys pending submissions older than the cutoff" do
    stale = backdate(create(:submission), 48)

    expect { described_class.perform_now(24) }
      .to change(Submission, :count).by(-1)
      .and change(SubmissionSong, :count).by(-1)

    expect(Submission.exists?(stale.id)).to be(false)
  end

  it "keeps recent pending submissions" do
    fresh = backdate(create(:submission), 1)
    described_class.perform_now(24)
    expect(Submission.exists?(fresh.id)).to be(true)
  end

  it "never touches paid submissions" do
    paid = backdate(create(:submission, :paid), 72)
    described_class.perform_now(24)
    expect(Submission.exists?(paid.id)).to be(true)
  end
end
