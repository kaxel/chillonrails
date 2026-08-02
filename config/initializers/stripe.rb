# Stripe configuration. Keys are read from the environment (see .env / Render env).
Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

Rails.application.config.stripe = {
  webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"]
}
