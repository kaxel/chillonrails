class AddUserToPosts < ActiveRecord::Migration[8.0]
  def change
    # Who wrote the post in the in-house editor. Imported posts have none.
    add_reference :posts, :user, null: true, foreign_key: true
  end
end
