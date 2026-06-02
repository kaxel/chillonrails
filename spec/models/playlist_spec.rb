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
end
