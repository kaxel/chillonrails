class CreateSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :submissions do |t|
      t.string :contact_name, null: false
      t.string :email, null: false
      t.string :artist_name, null: false
      t.string :status, null: false, default: "pending"
      t.integer :amount_cents, null: false, default: 0
      t.string :stripe_session_id
      t.string :token, null: false

      t.timestamps
    end

    add_index :submissions, :token, unique: true
    add_index :submissions, :stripe_session_id, unique: true
    add_index :submissions, :status
  end
end
