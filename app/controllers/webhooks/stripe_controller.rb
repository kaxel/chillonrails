module Webhooks
  class StripeController < ApplicationController
    allow_unauthenticated_access only: [ :create ]
    skip_forgery_protection only: [ :create ]

    def create
      payload = request.body.read
      signature = request.env["HTTP_STRIPE_SIGNATURE"]
      secret = Rails.application.config.stripe[:webhook_secret]

      begin
        event = Stripe::Webhook.construct_event(payload, signature, secret)
      rescue JSON::ParserError, Stripe::SignatureVerificationError => e
        Rails.logger.warn("Rejected Stripe webhook: #{e.message}")
        return head :bad_request
      end

      handle_event(event)
      head :ok
    end

    private

    def handle_event(event)
      case event.type
      when "checkout.session.completed"
        fulfill(event.data.object)
      when "payment_intent.succeeded"
        record_donation(event.data.object)
      end
    end

    def fulfill(checkout_session)
      submission = Submission.find_by(id: checkout_session.metadata&.submission_id) ||
                   Submission.find_by(stripe_session_id: checkout_session.id)
      return unless submission
      return if submission.paid?

      submission.mark_paid!
      SubmissionMailer.confirmation(submission).deliver_later
    end

    # Song submissions pay via Checkout Sessions, which create a PaymentIntent
    # under the hood too — so payment_intent.succeeded fires for those as well.
    # Only record a Donation for intents this app created for the support page.
    def record_donation(payment_intent)
      return unless payment_intent.metadata&.[]("source") == "support_page"
      return if Donation.exists?(stripe_payment_intent_id: payment_intent.id)

      Donation.create!(
        amount_cents: payment_intent.amount_received,
        stripe_payment_intent_id: payment_intent.id,
        status: "paid"
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to record donation for #{payment_intent.id}: #{e.message}")
    end
  end
end
