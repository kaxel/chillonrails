class AddScoreFieldsToPosts < ActiveRecord::Migration[8.0]
  def change
    change_table :posts, bulk: true do |t|
      t.integer :score, default: 0, null: false
      t.integer :score_all_time, default: 0, null: false
    end

    # Add indexes for performance if you plan to query/sort by these fields
    add_index :posts, :score
    add_index :posts, :score_all_time
  end
end
