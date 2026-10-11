require "rails_helper"

RSpec.describe ContactMailer, type: :mailer do
  describe "#message_received" do
    let(:contact_message) do
      ContactMessage.create!(name: "Jane Doe", email: "jane@example.com", message: "Love the station.\nKeep it up!")
    end
    let(:mail) { described_class.with(contact_message: contact_message).message_received }

    it "goes to the CHILLFILTR inbox from the site address" do
      expect(mail.to).to eq([ "info@chillfiltr.com" ])
      expect(mail.from).to eq([ "info@chillfiltr.com" ])
    end

    it "sets Reply-To to the visitor so replying answers them" do
      expect(mail.reply_to).to eq([ "jane@example.com" ])
      expect(mail[:reply_to].to_s).to include("Jane Doe")
    end

    it "names the sender in the subject" do
      expect(mail.subject).to eq("Contact form: Jane Doe")
    end

    it "labels the subject when the message looks like link spam" do
      spammy = ContactMessage.create!(name: "Jane", email: "jane@example.com", message: "http://a.example http://b.example http://c.example")
      subject = described_class.with(contact_message: spammy).message_received.subject
      expect(subject).to eq("[Possible spam] Contact form: Jane")
    end

    it "includes the message in both the text and HTML parts" do
      expect(mail.text_part.body.to_s).to include("Love the station.", "Keep it up!", "jane@example.com")
      expect(mail.html_part.body.to_s).to include("Love the station.", "Keep it up!")
    end

    it "escapes HTML in the message" do
      hostile = ContactMessage.create!(name: "Jane", email: "jane@example.com", message: "<script>alert(1)</script>")
      body = described_class.with(contact_message: hostile).message_received.html_part.body.to_s
      expect(body).not_to include("<script>")
    end

    it "records when the email was actually delivered" do
      expect(contact_message.delivered_at).to be_nil

      mail.deliver_now

      expect(contact_message.reload.delivered_at).to be_within(5.seconds).of(Time.current)
    end

    it "leaves the message undelivered if sending fails" do
      allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(Net::SMTPFatalError.new("550 sender not verified"))

      expect { mail.deliver_now }.to raise_error(Net::SMTPFatalError)
      expect(contact_message.reload.delivered_at).to be_nil
    end
  end
end
