require "rails_helper"

RSpec.describe BandcampEmbed do
  def page(type, id)
    %(<html><head><meta name="bc-page-properties" content="{&quot;item_type&quot;:&quot;#{type}&quot;,&quot;item_id&quot;:#{id},&quot;tralbum_page_version&quot;:0}"></head></html>)
  end

  describe ".candidate?" do
    it "accepts bandcamp.com pages, custom-domain track/album pages and player URLs" do
      expect(described_class.candidate?("https://kristeraxel.bandcamp.com/track/still-feels-broken")).to be true
      expect(described_class.candidate?("https://axelradio.com/album/follow-the-light")).to be true
      expect(described_class.candidate?("https://bandcamp.com/EmbeddedPlayer/track=1/")).to be true
    end

    it "rejects audio files and other links" do
      expect(described_class.candidate?("https://cdn.example.com/track/song.mp3")).to be false
      expect(described_class.candidate?("https://chillfiltr.s3.amazonaws.com/episode.mp3")).to be false
      expect(described_class.candidate?("https://example.com/blog/post")).to be false
      expect(described_class.candidate?("not a url")).to be false
    end
  end

  describe ".player_url_for" do
    it "builds a track player URL from the page's metadata" do
      allow(described_class).to receive(:fetch).and_return(page("t", 2293246886))
      expect(described_class.player_url_for("https://kristeraxel.bandcamp.com/track/still-feels-broken"))
        .to start_with("https://bandcamp.com/EmbeddedPlayer/track=2293246886/size=large/")
    end

    it "builds an album player URL" do
      allow(described_class).to receive(:fetch).and_return(page("a", 3450755065))
      expect(described_class.player_url_for("https://axelradio.com/album/follow-the-light"))
        .to start_with("https://bandcamp.com/EmbeddedPlayer/album=3450755065/")
    end

    it "uses a pasted player URL as-is without fetching" do
      expect(described_class).not_to receive(:fetch)
      url = "https://bandcamp.com/EmbeddedPlayer/track=1/size=small/"
      expect(described_class.player_url_for(url)).to eq(url)
    end

    it "returns nil when the page has no Bandcamp metadata or can't be fetched" do
      allow(described_class).to receive(:fetch).and_return("<html></html>")
      expect(described_class.player_url_for("https://axelradio.com/track/x")).to be_nil

      allow(described_class).to receive(:fetch).and_return(nil)
      expect(described_class.player_url_for("https://axelradio.com/track/x")).to be_nil
    end
  end
end
