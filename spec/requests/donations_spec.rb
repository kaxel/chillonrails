require 'rails_helper'

RSpec.describe "Donations", type: :request do
  describe "GET /pages/support" do
    it "renders the donation form without authentication" do
      get pages_support_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Thank You for Your Support")
    end
  end

  describe "POST /donations" do
    let(:intent) { double("Stripe::PaymentIntent", client_secret: "pi_test_secret_123") }

    before { allow(Stripe::PaymentIntent).to receive(:create).and_return(intent) }

    it "creates a PaymentIntent for a valid $5-increment amount" do
      post donations_path, params: { amount_cents: 1000 }, as: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["client_secret"]).to eq("pi_test_secret_123")
      expect(Stripe::PaymentIntent).to have_received(:create).with(
        hash_including(amount: 1000, currency: "usd", payment_method_types: [ "card" ])
      )
    end

    it "rejects an amount below the minimum" do
      post donations_path, params: { amount_cents: 100 }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Stripe::PaymentIntent).not_to have_received(:create)
    end

    it "rejects an amount that isn't a $5 increment" do
      post donations_path, params: { amount_cents: 733 }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Stripe::PaymentIntent).not_to have_received(:create)
    end
  end
end
