require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_have_enqueued_mail, :have_enqueued_mail

RSpec.describe "Contact form", type: :request do
  # A token as it would have been rendered into the form some seconds ago.
  def form_token(seconds_ago: 10)
    travel_to(seconds_ago.seconds.ago) { ContactMessage.new_form_token }
  end

  def params_with(**fields)
    { contact_message: { name: "Jane Doe", email: "jane@example.com", message: "Love the station.", form_token: form_token }.merge(fields) }
  end

  let(:valid_params) { params_with }

  describe "GET /pages/contact" do
    it "shows the native form, not the old third-party one" do
      get pages_contact_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(contact_messages_path)
      expect(response.body).not_to include("web3forms")
    end

    it "includes a signed timestamp for the fill-time check" do
      get pages_contact_path

      token = response.body[/name="contact_message\[form_token\]"[^>]*value="([^"]+)"/, 1] ||
              response.body[/value="([^"]+)"[^>]*name="contact_message\[form_token\]"/, 1]
      expect(token).to be_present
      expect(ContactMessage.form_token_verifier.verified(CGI.unescapeHTML(token), purpose: :contact_form)).to be_a(Integer)
    end
  end

  describe "POST /contact" do
    it "saves the message, emails it, and sends the visitor to the thank-you page" do
      expect {
        post contact_messages_path, params: valid_params
      }.to change(ContactMessage, :count).by(1)
        .and have_enqueued_mail(ContactMailer, :message_received)

      saved = ContactMessage.last
      expect(saved).to have_attributes(name: "Jane Doe", email: "jane@example.com", message: "Love the station.", delivered_at: nil, suspected_spam: false)
      expect(response).to redirect_to(pages_thanks_path)
    end

    it "does not need the visitor to be signed in" do
      post contact_messages_path, params: valid_params
      expect(response).not_to redirect_to(new_session_path)
    end

    it "re-renders the form with errors, saving and sending nothing, when the input is invalid" do
      expect {
        post contact_messages_path, params: params_with(name: "", email: "nope", message: "")
      }.to not_change(ContactMessage, :count)
        .and not_have_enqueued_mail(ContactMailer, :message_received)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Name can")
    end

    it "keeps what the visitor typed, and gives the form a fresh timestamp, when it is re-rendered" do
      post contact_messages_path, params: params_with(name: "Jane", email: "bad", message: "Hello there")
      expect(response.body).to include("Hello there")
      expect(response.body).to include("contact_message[form_token]")
    end

    it "handles a request with no form fields at all" do
      post contact_messages_path
      expect(response).to redirect_to(pages_thanks_path)
    end

    describe "spam handling" do
      def expect_silently_dropped(params)
        expect {
          post contact_messages_path, params: params
        }.to not_change(ContactMessage, :count)
          .and not_have_enqueued_mail(ContactMailer, :message_received)

        # Bots are told it worked so they learn nothing.
        expect(response).to redirect_to(pages_thanks_path)
      end

      it "drops submissions that fill the honeypot" do
        expect_silently_dropped(params_with(website: "http://spam.example"))
      end

      it "drops submissions with no form token (a bot posting straight to the endpoint)" do
        expect_silently_dropped(params_with(form_token: nil))
      end

      it "drops submissions with a forged form token" do
        expect_silently_dropped(params_with(form_token: "not-a-real-token"))
      end

      it "drops submissions made faster than a person could write them" do
        expect_silently_dropped(params_with(form_token: form_token(seconds_ago: 1)))
      end

      it "accepts a submission once the minimum time has passed" do
        expect {
          post contact_messages_path, params: params_with(form_token: form_token(seconds_ago: ContactMessage::MIN_FILL_SECONDS + 1))
        }.to change(ContactMessage, :count).by(1)
      end

      it "logs why a message was dropped, without the visitor's details" do
        allow(Rails.logger).to receive(:info)

        post contact_messages_path, params: params_with(website: "http://spam.example", email: "private@example.com")

        expect(Rails.logger).to have_received(:info).with("Contact form spam dropped (honeypot)")
      end

      it "labels a message full of links as possible spam, but still saves and emails it" do
        links = "Visit http://a.example and https://b.example and www.c.example today"

        expect {
          post contact_messages_path, params: params_with(message: links)
        }.to change(ContactMessage, :count).by(1)
          .and have_enqueued_mail(ContactMailer, :message_received)

        expect(ContactMessage.last).to be_suspected_spam
        expect(response).to redirect_to(pages_thanks_path)
      end

      it "does not label an ordinary message that mentions a link or two" do
        post contact_messages_path, params: params_with(message: "I wrote about you at https://example.com/post and www.example.org too.")
        expect(ContactMessage.last).not_to be_suspected_spam
      end
    end
  end
end
