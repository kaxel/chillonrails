FactoryBot.define do
  factory :donation do
    amount_cents { Donation::DEFAULT_AMOUNT_CENTS }
    sequence(:stripe_payment_intent_id) { |n| "pi_test_#{n}" }
    status { "paid" }
  end
end
