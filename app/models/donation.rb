class Donation < ApplicationRecord
  DEFAULT_AMOUNT_CENTS = 500
  INCREMENT_CENTS = 500
  MIN_AMOUNT_CENTS = 500

  validates :amount_cents, :stripe_payment_intent_id, :status, presence: true
  validates :amount_cents, numericality: { greater_than_or_equal_to: MIN_AMOUNT_CENTS }
  validates :stripe_payment_intent_id, uniqueness: true
  validates :status, inclusion: { in: %w[paid] }

  def amount_dollars
    amount_cents / 100.0
  end
end
