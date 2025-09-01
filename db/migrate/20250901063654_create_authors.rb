class CreateAuthors < ActiveRecord::Migration[8.0]
  def change
    create_table :authors do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :collection_id
      t.string :locale_id
      t.string :item_id, index: { unique: true }
      t.boolean :archived, default: false
      t.boolean :draft, default: false
      t.datetime :created_on
      t.datetime :updated_on
      t.datetime :published_on
      t.string :author_photo
      t.string :author_email
      t.string :author_position
      t.text :about_author
      t.string :social_profile_link_1
      t.string :social_profile_link_2
      t.string :social_profile_link_3
      t.boolean :editorial_chief, default: false
      t.string :location

      t.timestamps
    end
  end
end
