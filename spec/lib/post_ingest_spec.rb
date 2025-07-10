require 'rails_helper'

SAMPLE_LINE_ITEM = "MICHA - Hopeful,micha---hopeful,Thu Dec 26 2024 04:00:32 GMT+0000 (Coordinated Universal Time),https://cdn.prod.website-files.com/65511e3719795897b270b804/6764af8bd969a127c955ed9c_micha---promo--lores.jpg,An abiding sense that these melodies extend from a tender place deep within the human heart.,krister-axel,3,music,Fri Dec 20 2024 00:00:00 GMT+0000 (Coordinated Universal Time),indie; folk; roots,nashville; tennessee; usa,,https://storage.googleapis.com/chillfiltr-music/song-sub/MICHA%20-%20Hopeful.mp3"

describe PostIngest do
  let(:name) { "Test Name" }
  let(:post_ingest) { PostIngest.new(name) }

  describe "#initialize" do
    it "sets the name instance variable" do
      expect(post_ingest.instance_variable_get(:@name)).to eq(name)
    end
  end

  describe "#greeting" do
    it "returns a greeting with the name" do
      expect(post_ingest.greeting).to eq("Hello, Test Name!")
    end
  end
  
  describe "#parse new line" do
    it "breaks down csv line" do
      post_ingest.feed_line(SAMPLE_LINE_ITEM)
      expect(post_ingest.slug).to eq("micha---hopeful")
      expect(post_ingest.created_on).to eq("2024-12-26")
      expect(post_ingest.preview).to eq("An abiding sense that these melodies extend from a tender place deep within the human heart.")
      expect(post_ingest.image).to eq("https://cdn.prod.website-files.com/65511e3719795897b270b804/6764af8bd969a127c955ed9c_micha---promo--lores.jpg")
    end
  end  

  
end