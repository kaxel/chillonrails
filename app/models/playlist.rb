class Playlist < ApplicationRecord
  validates :name, presence: true

  attribute :songs, :jsonb, default: -> { {} }

  # "…/Krister%20Axel_-_Fast_Train.mp3" -> "Krister Axel - Fast Train"
  def self.song_title(url)
    File.basename(url.to_s, ".mp3").gsub("%20", " ").gsub("_", " ").squish
  end

  # Display titles in play order (the jsonb keys are the 1-based track numbers).
  def song_titles
    songs.sort_by { |position, _url| position.to_i }.map { |_position, url| self.class.song_title(url) }
  end
end
