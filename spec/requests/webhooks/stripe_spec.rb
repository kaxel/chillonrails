require 'rails_helper'

RSpec.describe "Webhooks::Stripe", type: :request do
  let(:submission) { create(:submission) }

  def stripe_event(submission_id:, session_id: submission.stripe_session_id || "cs_test_123")
    Stripe::Event.construct_from(
      type: "checkout.session.completed",
      data: { object: { id: session_id, metadata: { submission_id: submission_id } } }
    )
  end

  it "marks the submission paid and enqueues the confirmation email" do
    allow(Stripe::Webhook).to receive(:construct_event).and_return(stripe_event(submission_id: submission.id))

    expect {
      post webhooks_stripe_path, params: "{}", headers: { "HTTP_STRIPE_SIGNATURE" => "sig" }
    }.to have_enqueued_mail(SubmissionMailer, :confirmation)

    expect(response).to have_http_status(:ok)
    expect(submission.reload).to be_paid
  end

  it "is idempotent — a second delivery does not re-send email" do
    submission.mark_paid!
    allow(Stripe::Webhook).to receive(:construct_event).and_return(stripe_event(submission_id: submission.id))

    expect {
      post webhooks_stripe_path, params: "{}", headers: { "HTTP_STRIPE_SIGNATURE" => "sig" }
    }.not_to have_enqueued_mail(SubmissionMailer, :confirmation)
    expect(response).to have_http_status(:ok)
  end

  it "rejects a request with a bad signature" do
    allow(Stripe::Webhook).to receive(:construct_event)
      .and_raise(Stripe::SignatureVerificationError.new("bad sig", "sig"))

    post webhooks_stripe_path, params: "{}", headers: { "HTTP_STRIPE_SIGNATURE" => "sig" }
    expect(response).to have_http_status(:bad_request)
  end

  def payment_intent_event(id: "pi_test_123", amount_received: 500, metadata: { source: "support_page" })
    Stripe::Event.construct_from(
      type: "payment_intent.succeeded",
      data: { object: { id: id, amount_received: amount_received, metadata: metadata } }
    )
  end

  it "records a donation for a support-page payment intent" do
    allow(Stripe::Webhook).to receive(:construct_event).and_return(payment_intent_event)

    expect {
      post webhooks_stripe_path, params: "{}", headers: { "HTTP_STRIPE_SIGNATURE" => "sig" }
    }.to change(Donation, :count).by(1)

    donation = Donation.last
    expect(donation.stripe_payment_intent_id).to eq("pi_test_123")
    expect(donation.amount_cents).to eq(500)
    expect(donation.status).to eq("paid")
  end

  it "does not record a donation for a submission's underlying payment intent" do
    allow(Stripe::Webhook).to receive(:construct_event).and_return(payment_intent_event(metadata: {}))

    expect {
      post webhooks_stripe_path, params: "{}", headers: { "HTTP_STRIPE_SIGNATURE" => "sig" }
    }.not_to change(Donation, :count)
  end

  it "is idempotent — a second delivery does not create a duplicate donation" do
    create(:donation, stripe_payment_intent_id: "pi_test_123")
    allow(Stripe::Webhook).to receive(:construct_event).and_return(payment_intent_event)

    expect {
      post webhooks_stripe_path, params: "{}", headers: { "HTTP_STRIPE_SIGNATURE" => "sig" }
    }.not_to change(Donation, :count)
  end
end
