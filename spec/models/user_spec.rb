require 'rails_helper'
require 'ostruct'

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with an email and password" do
      expect(build(:user)).to be_valid
    end

    it "requires an email address" do
      expect(build(:user, email_address: nil)).not_to be_valid
    end

    it "requires a unique email address" do
      create(:user, email_address: "dup@example.com")
      expect(build(:user, email_address: "dup@example.com")).not_to be_valid
    end

    it "rejects a malformed email address" do
      expect(build(:user, email_address: "not-an-email")).not_to be_valid
    end

    it "requires a password for email-based users" do
      expect(build(:user, password: nil)).not_to be_valid
    end

    it "does not require a password for oauth users" do
      expect(build(:user, :oauth)).to be_valid
    end
  end

  describe "email normalization" do
    it "strips and downcases the email address" do
      user = create(:user, email_address: "  MixedCase@Example.COM  ")
      expect(user.email_address).to eq("mixedcase@example.com")
    end
  end

  describe "admin restriction" do
    it "rejects granting admin to an unauthorized account" do
      user = build(:user, email_address: "someone@example.com", admin: true)
      expect(user).not_to be_valid
      expect(user.errors[:admin]).to be_present
    end

    it "allows granting admin to the authorized account" do
      user = build(:user, email_address: "songlistrnet@gmail.com", admin: true)
      expect(user).to be_valid
    end
  end

  describe "#confirm!" do
    it "sets confirmed_at and clears the confirmation token" do
      user = create(:user)
      user.confirm!
      expect(user.confirmed_at).to be_present
      expect(user.confirmation_token).to be_nil
    end
  end

  describe "#confirmed?" do
    it "is true when confirmed_at is set" do
      expect(build(:user, :confirmed).confirmed?).to be(true)
    end

    it "is false when confirmed_at is blank" do
      expect(build(:user, confirmed_at: nil).confirmed?).to be(false)
    end
  end

  describe "#oauth_user?" do
    it "is true when provider and uid are present" do
      expect(build(:user, :oauth).oauth_user?).to be(true)
    end

    it "is false for email-based users" do
      expect(build(:user).oauth_user?).to be(false)
    end
  end

  describe "#profile_image_url" do
    it "returns nil when there is no profile image" do
      expect(build(:user, profile_image: nil).profile_image_url).to be_nil
    end

    it "appends a size parameter for Google images" do
      user = build(:user, :oauth,
        profile_image: "https://lh3.googleusercontent.com/a/photo")
      expect(user.profile_image_url(size: 200)).to eq("https://lh3.googleusercontent.com/a/photo=s200-c")
    end

    it "returns the raw url for non-Google images" do
      user = build(:user, profile_image: "https://example.com/me.png")
      expect(user.profile_image_url).to eq("https://example.com/me.png")
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OpenStruct.new(
        provider: "google_oauth2",
        uid: "12345",
        info: OpenStruct.new(email: "oauth@example.com", image: "https://img/avatar.png")
      )
    end

    it "creates a new confirmed user when none exists" do
      expect { User.from_omniauth(auth) }.to change(User, :count).by(1)
      user = User.find_by(uid: "12345")
      expect(user.email_address).to eq("oauth@example.com")
      expect(user).to be_confirmed
    end

    it "returns and updates the image for an existing oauth user" do
      existing = create(:user, :oauth, uid: "12345", profile_image: "old.png")
      result = User.from_omniauth(auth)
      expect(result).to eq(existing)
      expect(result.reload.profile_image).to eq("https://img/avatar.png")
    end

    it "links oauth to an existing account with the same email" do
      existing = create(:user, email_address: "oauth@example.com")
      expect { User.from_omniauth(auth) }.not_to change(User, :count)
      existing.reload
      expect(existing.provider).to eq("google_oauth2")
      expect(existing.uid).to eq("12345")
    end
  end
end
