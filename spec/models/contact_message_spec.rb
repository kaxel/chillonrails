require "rails_helper"

RSpec.describe ContactMessage do
  def build_message(**overrides)
    described_class.new({ name: "Jane Doe", email: "jane@example.com", message: "Love the station." }.merge(overrides))
  end

  it "is valid with a name, email, and message" do
    expect(build_message).to be_valid
  end

  it "requires a name, email, and message" do
    message = described_class.new
    expect(message).not_to be_valid
    expect(message.errors.attribute_names).to contain_exactly(:name, :email, :message)
  end

  it "rejects a malformed email" do
    expect(build_message(email: "not-an-email")).not_to be_valid
  end

  it "rejects line breaks in the name or email, which would let a sender inject email headers" do
    expect(build_message(name: "Jane\r\nBcc: victim@example.com")).not_to be_valid
    expect(build_message(email: "jane@example.com\nBcc: victim@example.com")).not_to be_valid
  end

  it "limits the length of each field" do
    expect(build_message(name: "a" * 201)).not_to be_valid
    expect(build_message(message: "a" * 5001)).not_to be_valid
    expect(build_message(message: "a" * 5000)).to be_valid
  end

  describe "#spam?" do
    it "is true only when the honeypot field is filled in" do
      expect(build_message).not_to be_spam
      expect(build_message(website: "http://spam.example")).to be_spam
    end

    it "never stores the honeypot value" do
      expect(described_class.column_names).not_to include("website")
    end
  end

  describe ".undelivered" do
    it "finds messages whose email has not gone out yet" do
      waiting = build_message.tap(&:save!)
      sent = build_message.tap { |m| m.delivered_at = Time.current }.tap(&:save!)

      expect(described_class.undelivered).to include(waiting)
      expect(described_class.undelivered).not_to include(sent)
    end
  end
end
