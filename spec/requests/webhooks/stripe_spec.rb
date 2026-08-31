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
end
