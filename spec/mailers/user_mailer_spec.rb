require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#confirmation_instructions" do
    let(:user) { create(:user, email_address: "confirm@example.com") }
    let(:mail) { described_class.confirmation_instructions(user) }

    it "uses the localized confirm subject" do
      expect(mail.subject).to eq(I18n.t("registrations.confirm_account_subject"))
    end

    it "is addressed to the user" do
      expect(mail.to).to eq([ "confirm@example.com" ])
    end

    it "links to the confirmation url with the user's token" do
      expect(mail.body.encoded).to include("/registration/confirm")
      expect(mail.body.encoded).to include(user.confirmation_token)
    end
  end
end
