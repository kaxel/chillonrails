require 'rails_helper'

RSpec.describe Donation, type: :model do
  it "builds a valid donation from the factory" do
    expect(build(:donation)).to be_valid
  end

  it "requires an amount, a payment intent id, and a status" do
    donation = build(:donation, amount_cents: nil, stripe_payment_intent_id: nil, status: nil)
    expect(donation).not_to be_valid
    expect(donation.errors.attribute_names).to include(:amount_cents, :stripe_payment_intent_id, :status)
  end

  it "rejects an amount below the $5 minimum" do
    expect(build(:donation, amount_cents: 100)).not_to be_valid
  end

  it "rejects a duplicate payment intent id" do
    create(:donation, stripe_payment_intent_id: "pi_dup")
    expect(build(:donation, stripe_payment_intent_id: "pi_dup")).not_to be_valid
  end

  it "converts cents to dollars" do
    expect(build(:donation, amount_cents: 1500).amount_dollars).to eq(15.0)
  end
end
