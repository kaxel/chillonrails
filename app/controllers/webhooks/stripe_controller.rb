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
  end
end
