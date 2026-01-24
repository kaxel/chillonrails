class AddOauthToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :provider
      t.string :uid
      t.index [ :provider, :uid ], unique: true
    end
  end
end
