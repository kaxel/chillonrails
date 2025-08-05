class CreatePageNotFounds < ActiveRecord::Migration[8.0]
  def change
    create_table :page_not_founds do |t|
      t.string :url
      t.datetime :accessed_at

      t.timestamps
    end
  end
end
