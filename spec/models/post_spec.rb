require 'rails_helper'

RSpec.describe Post, type: :model do
  describe "validations" do
    it "is valid with a title and content" do
      expect(build(:post)).to be_valid
    end

    it "requires a title" do
      expect(build(:post, title: nil)).not_to be_valid
    end

    it "requires content" do
      expect(build(:post, content: nil)).not_to be_valid
    end

    it "requires a unique slug" do
      create(:post, title: "Same Title")
      expect(build(:post, title: "Same Title")).not_to be_valid
    end

    it "accepts a blank video_link" do
      expect(build(:post, video_link: "")).to be_valid
    end

    it "rejects an invalid video_link" do
      expect(build(:post, video_link: "not a url")).not_to be_valid
    end

    it "accepts a valid video_link" do
      expect(build(:post, video_link: "https://youtu.be/abc123")).to be_valid
    end

    it "rejects an invalid audio_link" do
      expect(build(:post, audio_link: "not a url")).not_to be_valid
    end
  end

  describe "slug generation" do
    it "generates a slug from the title when blank" do
      post = build(:post, title: "Hello World", slug: nil)
      post.valid?
      expect(post.slug).to eq("hello-world")
    end

    it "does not overwrite a provided slug" do
      post = build(:post, title: "Hello World", slug: "custom-slug")
      post.valid?
      expect(post.slug).to eq("custom-slug")
    end
  end

  describe "preview generation" do
    it "truncates content to 200 characters when preview is blank" do
      post = build(:post, content: "a" * 500, preview: nil)
      post.valid?
      expect(post.preview.length).to eq(200)
    end

    it "does not overwrite a provided preview" do
      post = build(:post, content: "a" * 500, preview: "custom preview")
      post.valid?
      expect(post.preview).to eq("custom preview")
    end
  end

  describe ".by_topic" do
    it "filters posts by topic" do
      music = create(:post, topic: "music")
      create(:post, topic: "poetry")
      expect(Post.by_topic("music")).to contain_exactly(music)
    end
  end

  describe "#locations_from_hash" do
    it "titleizes semicolon-delimited locations and normalizes USA/UK" do
      post = build(:post, location: "los angeles;usa;uk")
      expect(post.locations_from_hash).to eq([ "Los Angeles", "USA", "UK" ])
    end
  end

  describe "#tags_from_hash" do
    it "titleizes semicolon-delimited tags" do
      post = build(:post, tags: "indie;lo fi")
      expect(post.tags_from_hash).to eq([ "Indie", "Lo Fi" ])
    end

    it "removes a redundant prose tag from the front" do
      post = build(:post, tags: "prose;short story")
      expect(post.tags_from_hash).to eq([ "Short Story" ])
    end

    # Characterization test: a lone "poetry" tag is NOT stripped because the
    # later prose branch re-reads the original tags string and overwrites the
    # poetry removal. Pinning current behavior so a future refactor is deliberate.
    it "keeps a poetry tag when no prose tag is present (current behavior)" do
      post = build(:post, tags: "poetry;melancholy")
      expect(post.tags_from_hash).to eq([ "Poetry", "Melancholy" ])
    end
  end

  describe "Bandcamp audio links" do
    let(:player) { "https://bandcamp.com/EmbeddedPlayer/track=2293246886/size=large/" }

    it "stores the Bandcamp player for a Bandcamp audio link" do
      allow(BandcampEmbed).to receive(:player_url_for).and_return(player)
      post = create(:post, audio_link: "https://kristeraxel.bandcamp.com/track/still-feels-broken")
      expect(post.audio_embed_url).to eq(player)
    end

    it "rejects a Bandcamp link with no player" do
      allow(BandcampEmbed).to receive(:player_url_for).and_return(nil)
      post = build(:post, audio_link: "https://kristeraxel.bandcamp.com/track/gone")
      expect(post).not_to be_valid
      expect(post.errors[:audio_link]).to be_present
    end

    it "leaves mp3 links alone and clears a previous player" do
      allow(BandcampEmbed).to receive(:player_url_for).and_return(player)
      post = create(:post, audio_link: "https://kristeraxel.bandcamp.com/track/still-feels-broken")
      post.update!(audio_link: "https://cdn.example.com/episode.mp3")
      expect(post.audio_embed_url).to be_nil
    end

    it "doesn't look anything up when the audio link is unchanged" do
      allow(BandcampEmbed).to receive(:player_url_for).and_return(player)
      post = create(:post, audio_link: "https://kristeraxel.bandcamp.com/track/still-feels-broken")
      post.update!(title: "Renamed")
      expect(BandcampEmbed).to have_received(:player_url_for).once
    end
  end
end
