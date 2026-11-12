require 'rails_helper'

RSpec.describe Playlist, type: :model do
  describe "validations" do
    it "is valid with a name" do
      expect(build(:playlist)).to be_valid
    end

    it "requires a name" do
      expect(build(:playlist, name: nil)).not_to be_valid
    end
  end

  describe "songs attribute" do
    it "defaults to an empty hash" do
      expect(Playlist.new.songs).to eq({})
    end

    it "persists jsonb song data" do
      playlist = create(:playlist, songs: { "1" => "Song One" })
      expect(playlist.reload.songs).to eq({ "1" => "Song One" })
    end
  end

  describe ".song_title" do
    it "turns a storage URL into a display title" do
      url = "https://storage.googleapis.com/chillfiltr-music/song-sub/Krister%20Axel_-_Fast_Train.mp3"
      expect(Playlist.song_title(url)).to eq("Krister Axel - Fast Train")
    end

    it "collapses runs of separators left by underscores in the filename" do
      expect(Playlist.song_title("https://x.test/K_Axel__Train_to_Cry.mp3")).to eq("K Axel Train to Cry")
    end
  end

  describe "#song_titles" do
    it "lists titles in play order by track number, not insertion order" do
      playlist = build(:playlist, songs: { "10" => "https://x.test/Ten.mp3", "2" => "https://x.test/Two.mp3", "1" => "https://x.test/One.mp3" })
      expect(playlist.song_titles).to eq(%w[One Two Ten])
    end

    it "is empty for a playlist with no songs" do
      expect(build(:playlist, songs: {}).song_titles).to eq([])
    end
  end
end
