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
    def token_from(seconds_ago)
      travel_to(seconds_ago.seconds.ago) { described_class.new_form_token }
    end

    it "is false for a person: a valid token that is old enough, and an empty honeypot" do
      message = build_message(form_token: token_from(10))
      expect(message).not_to be_spam
      expect(message.spam_reason).to be_nil
    end

    it "catches the honeypot" do
      message = build_message(form_token: token_from(10), website: "http://spam.example")
      expect(message).to be_spam
      expect(message.spam_reason).to eq(:honeypot)
    end

    it "catches a submission made too soon after the form was shown" do
      expect(build_message(form_token: token_from(0))).to be_spam
      expect(build_message(form_token: token_from(described_class::MIN_FILL_SECONDS - 1))).to be_spam
      expect(build_message(form_token: token_from(0)).spam_reason).to eq(:too_fast)
    end

    it "allows a submission right at the minimum time" do
      expect(build_message(form_token: token_from(described_class::MIN_FILL_SECONDS))).not_to be_spam
    end

    it "treats a missing, forged, or wrong-purpose token as a bot" do
      expect(build_message(form_token: nil)).to be_spam
      expect(build_message(form_token: "")).to be_spam
      expect(build_message(form_token: "forged")).to be_spam
      wrong_purpose = described_class.form_token_verifier.generate(1.minute.ago.to_i, purpose: :something_else)
      expect(build_message(form_token: wrong_purpose)).to be_spam
    end

    it "rejects a token that has expired" do
      old = token_from((described_class::FORM_TOKEN_LIFETIME + 1.day).to_i)
      expect(build_message(form_token: old)).to be_spam
    end

    it "never stores the honeypot or the token" do
      expect(described_class.column_names).not_to include("website", "form_token")
    end
  end

  describe "#suspicious_links?" do
    it "is false for messages with no, one, or two links" do
      expect(build_message(message: "No links here.")).not_to be_suspicious_links
      expect(build_message(message: "See https://example.com for more.")).not_to be_suspicious_links
      expect(build_message(message: "https://a.example and www.b.example")).not_to be_suspicious_links
    end

    it "is true at three or more links, whether http, https, or www" do
      expect(build_message(message: "http://a.example https://b.example www.c.example")).to be_suspicious_links
    end

    it "counts links stuffed into the name too" do
      expect(build_message(name: "http://a.example", message: "https://b.example www.c.example")).to be_suspicious_links
    end

    it "does not mistake ordinary words for links" do
      expect(build_message(message: "We use https and www a lot, and the web is great.")).not_to be_suspicious_links
    end
  end

  describe "labelling on save" do
    it "marks a link-heavy message as suspected spam" do
      message = build_message(message: "http://a.example http://b.example http://c.example")
      message.save!
      expect(message).to be_suspected_spam
    end

    it "leaves an ordinary message unmarked" do
      message = build_message.tap(&:save!)
      expect(message).not_to be_suspected_spam
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
