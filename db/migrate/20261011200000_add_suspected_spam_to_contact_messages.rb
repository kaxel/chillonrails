class AddSuspectedSpamToContactMessages < ActiveRecord::Migration[8.0]
  def change
    # Set when a message looks like link spam. These are still saved and
    # emailed (nothing real gets lost to a wrong guess), just labelled.
    add_column :contact_messages, :suspected_spam, :boolean, default: false, null: false
  end
end
