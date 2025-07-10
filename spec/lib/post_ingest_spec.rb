require 'rails_helper'

SAMPLE_LINE_ITEM = CSV.open("storage/CHILLFLOW - Articles - sample 100.csv", 'r', :headers => true) { |csv| csv.first }

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
      expect(post_ingest.slug).to eq("jonny-j-solo---fallen-leaves")
      expect(post_ingest.created_on).to eq("2024-12-18")
      expect(post_ingest.preview).to eq("An edgy folk style that feels both authentic and slightly wounded.")
      expect(post_ingest.image).to eq("https://cdn.prod.website-files.com/65511e3719795897b270b804/676342170f811f47205f618e_Jonny%20J%20Solo%20-%20promo.jpg")
      
      expect(post_ingest.author).to eq("krister-axel")
      expect(post_ingest.reading_time).to eq(3)
      expect(post_ingest.topic).to eq("music")
      expect(post_ingest.published_on).to eq("2024-12-18")
      expect(post_ingest.tags).to eq("folk; solo")
      expect(post_ingest.location).to eq("fairbanks; alaska; usa")
      expect(post_ingest.video).to eq("")
      expect(post_ingest.audio).to eq("https://storage.googleapis.com/chillfiltr-music/song-sub/Jonny%20J%20Solo%20-%20Fallen%20Leaves.mp3")
    end
  end  

  
end