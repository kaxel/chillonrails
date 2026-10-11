require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_have_enqueued_mail, :have_enqueued_mail

RSpec.describe "Contact form", type: :request do
  let(:valid_params) do
    { contact_message: { name: "Jane Doe", email: "jane@example.com", message: "Love the station." } }
  end

  describe "GET /pages/contact" do
    it "shows the native form, not the old third-party one" do
      get pages_contact_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(contact_messages_path)
      expect(response.body).not_to include("web3forms")
    end
  end

  describe "POST /contact" do
    it "saves the message, emails it, and sends the visitor to the thank-you page" do
      expect {
        post contact_messages_path, params: valid_params
      }.to change(ContactMessage, :count).by(1)
        .and have_enqueued_mail(ContactMailer, :message_received)

      saved = ContactMessage.last
      expect(saved).to have_attributes(name: "Jane Doe", email: "jane@example.com", message: "Love the station.", delivered_at: nil)
      expect(response).to redirect_to(pages_thanks_path)
    end

    it "does not need the visitor to be signed in" do
      post contact_messages_path, params: valid_params
      expect(response).not_to redirect_to(new_session_path)
    end

    it "re-renders the form with errors, saving and sending nothing, when the input is invalid" do
      expect {
        post contact_messages_path, params: { contact_message: { name: "", email: "nope", message: "" } }
      }.to not_change(ContactMessage, :count)
        .and not_have_enqueued_mail(ContactMailer, :message_received)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Name can")
    end

    it "keeps what the visitor typed when the form is re-rendered" do
      post contact_messages_path, params: { contact_message: { name: "Jane", email: "bad", message: "Hello there" } }
      expect(response.body).to include("Hello there")
    end

    it "silently drops submissions that fill the honeypot, without saving them" do
      spam = valid_params.deep_merge(contact_message: { website: "http://spam.example" })

      expect {
        post contact_messages_path, params: spam
      }.to not_change(ContactMessage, :count)
        .and not_have_enqueued_mail(ContactMailer, :message_received)

      expect(response).to redirect_to(pages_thanks_path)
    end

    it "handles a request with no form fields at all" do
      post contact_messages_path
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
