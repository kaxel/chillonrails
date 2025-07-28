class AddScoreFieldsToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :score, :integer, default: 0, null: false
    add_column :posts, :score_all_time, :integer, default: 0, null: false
    
    # Add indexes for performance if you plan to query/sort by these fields
    add_index :posts, :score
    add_index :posts, :score_all_time
  end
end
