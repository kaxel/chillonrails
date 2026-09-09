class CreateDonations < ActiveRecord::Migration[8.0]
  def change
    create_table :donations do |t|
      t.integer :amount_cents, null: false
      t.string :stripe_payment_intent_id, null: false
      t.string :status, null: false, default: "paid"

      t.timestamps
    end

    add_index :donations, :stripe_payment_intent_id, unique: true
  end
end
