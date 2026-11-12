class CreateContactMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_messages do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.text :message, null: false
      # Set when the notification email is actually sent. Blank means it was
      # saved but never delivered.
      t.datetime :delivered_at

      t.timestamps
    end

    add_index :contact_messages, :created_at
  end
end
