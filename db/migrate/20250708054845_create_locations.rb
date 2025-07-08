class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.string :slug
      t.text :description
      t.string :color
      t.timestamps
    end

    add_index :locations, :slug, unique: true
    add_index :locations, :name, unique: true
  end
end
