class CreateSubmissionSongs < ActiveRecord::Migration[8.0]
  def change
    create_table :submission_songs do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :title, null: false

      t.timestamps
    end
  end
end
