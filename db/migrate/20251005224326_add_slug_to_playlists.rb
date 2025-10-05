class AddSlugToPlaylists < ActiveRecord::Migration[8.0]
  def change
    add_column :playlists, :slug, :string
    add_index :playlists, :slug, unique: true

    reversible do |dir|
      dir.up do
        Playlist.find_each do |playlist|
          playlist.update_column(:slug, playlist.name.parameterize)
        end
      end
    end
  end
end
