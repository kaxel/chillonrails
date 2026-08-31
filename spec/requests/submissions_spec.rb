require 'rails_helper'

RSpec.describe "Submissions", type: :request do
  let(:audio) { fixture_file_upload("sample.mp3", "audio/mpeg") }

  def valid_params(songs: 1)
    attrs = {}
    songs.times { |i| attrs[i.to_s] = { title: "Track #{i}", audio: audio } }
    { submission: { contact_name: "Jane Doe", email: "jane@example.com",
                    artist_name: "The Janes", submission_songs_attributes: attrs } }
  end

  describe "GET /submit" do
    it "renders the submission form without authentication" do
      get submit_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Submit Your Music")
    end
  end

  describe "POST /submissions" do
    let(:checkout) { double("Stripe::Checkout::Session", id: "cs_test_123", url: "https://checkout.stripe.test/pay") }

    before { allow(Stripe::Checkout::Session).to receive(:create).and_return(checkout) }

    it "creates the submission, prices it, and redirects to Stripe" do
      expect {
        post submissions_path, params: valid_params(songs: 2)
      }.to change(Submission, :count).by(1)
        .and change(SubmissionSong, :count).by(2)

      submission = Submission.last
      expect(submission.amount_cents).to eq(600)
      expect(submission.stripe_session_id).to eq("cs_test_123")
      expect(submission.status).to eq("pending")
      expect(response).to redirect_to("https://checkout.stripe.test/pay")
    end

    it "passes the correct line item quantity and unit amount to Stripe" do
      post submissions_path, params: valid_params(songs: 3)
      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(
          mode: "payment",
          line_items: [ hash_including(quantity: 3, price_data: hash_including(unit_amount: 300)) ]
        )
      )
    end

    it "re-renders the form and creates nothing when invalid" do
      expect {
        post submissions_path, params: { submission: { contact_name: "", email: "bad" } }
      }.not_to change(Submission, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /submissions/:token/success" do
    it "shows the thank-you page for a valid token" do
      submission = create(:submission, :paid)
      get submission_success_path(submission.token)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Thank you")
    end

    it "404s for an unknown token" do
      get submission_success_path("nope")
      expect(response).to redirect_to("/404")
    end
  end
end
