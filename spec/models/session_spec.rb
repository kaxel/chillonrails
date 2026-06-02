require 'rails_helper'

RSpec.describe Session, type: :model do
  describe "associations" do
    it "belongs to a user" do
      session = build(:session)
      expect(session.user).to be_a(User)
    end

    it "requires a user" do
      expect(build(:session, user: nil)).not_to be_valid
    end
  end
end
