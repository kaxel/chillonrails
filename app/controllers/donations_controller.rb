class DonationsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @page_title = "support the channel"
    @default_amount_cents = Donation::DEFAULT_AMOUNT_CENTS
  end

  # Creates a Stripe PaymentIntent for the requested amount and hands the
  # client_secret back to the browser, which confirms the card payment
  # in place with stripe.js — no redirect, no page navigation. The Donation
  # record itself is only created once the webhook confirms payment (see
  # Webhooks::StripeController), so there's nothing to clean up if someone
  # abandons the form before paying.
  def create
    amount_cents = params[:amount_cents].to_i

    unless valid_amount?(amount_cents)
      return render json: { error: t("donations.invalid_amount") }, status: :unprocessable_entity
    end

    intent = Stripe::PaymentIntent.create(
      amount: amount_cents,
      currency: "usd",
      payment_method_types: [ "card" ],
      metadata: { source: "support_page" }
    )

    render json: { client_secret: intent.client_secret }
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe PaymentIntent failed for donation: #{e.message}")
    render json: { error: t("donations.payment_start_failed") }, status: :unprocessable_entity
  end

  private

  def valid_amount?(cents)
    cents >= Donation::MIN_AMOUNT_CENTS && cents % Donation::INCREMENT_CENTS == 0
  end
end
