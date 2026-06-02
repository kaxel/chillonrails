require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user, email_address: "reset@example.com") }
    let(:mail) { described_class.reset(user) }

    it "uses the localized reset subject" do
      expect(mail.subject).to eq(I18n.t("passwords.reset_subject"))
    end

    it "is addressed to the user" do
      expect(mail.to).to eq([ "reset@example.com" ])
    end

    it "links to the password edit page" do
      expect(mail.body.encoded).to include("/passwords/")
    end
  end
end
