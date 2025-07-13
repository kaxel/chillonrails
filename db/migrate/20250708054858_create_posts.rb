class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug
      t.text :content
      t.string :image
      t.string :video_link
      t.string :audio_link
      t.string :location
      t.string :tags
      t.text :preview
      t.string :topic
      t.string :author
      t.date :published_on
      t.timestamps
    end

    add_index :posts, :slug, unique: true
    add_index :posts, :topic
  end
end
