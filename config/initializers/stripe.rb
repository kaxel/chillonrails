# Stripe configuration. Keys are read from the environment (see .env / Render env).
Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

Rails.application.config.stripe = {
  webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"],
  # Publishable key is safe to expose client-side (it's what Stripe.js is built
  # for) — used by the donation form to mount the card Element in the browser.
  publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"]
}
