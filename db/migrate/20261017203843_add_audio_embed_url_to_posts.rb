class AddAudioEmbedUrlToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :audio_embed_url, :string
  end
end
