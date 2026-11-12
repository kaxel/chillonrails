require 'rails_helper'

RSpec.describe "Playlists", type: :request do
  describe "GET /playlist/:slug" do
    it "returns http success for an existing playlist" do
      playlist = create(:playlist, slug: "summer-mix")
      get playlist_path(playlist.slug)
      expect(response).to have_http_status(:success)
    end

    it "redirects to the 404 page for an unknown playlist" do
      get playlist_path("does-not-exist")
      expect(response).to redirect_to("/404")
    end
  end

  describe "link preview tags" do
    let(:playlist) do
      create(:playlist, name: "Summer Mix", slug: "summer-mix",
                        songs: { "2" => "https://x.test/B%20Band_-_Second.mp3", "1" => "https://x.test/A%20Band_-_First.mp3" })
    end
    let(:html) { get playlist_path(playlist.slug); Nokogiri::HTML(response.body) }

    def meta(doc, key)
      doc.at_css(%(meta[property="#{key}"], meta[name="#{key}"]))&.[]("content")
    end

    it "gives scrapers a playlist-specific title, description, image and canonical URL" do
      expect(html.at_css("title").text).to eq("Summer Mix — Playlist — CHILLFILTR®")
      expect(meta(html, "og:title")).to eq("Summer Mix — a CHILLFILTR® playlist")
      expect(meta(html, "og:description")).to eq("2 songs: A Band - First, B Band - Second.")
      expect(meta(html, "og:image")).to eq("http://www.example.com/social-playlist.png")
      expect(meta(html, "og:url")).to eq("http://www.example.com/playlist/summer-mix")
      expect(html.at_css('link[rel="canonical"]')["href"]).to eq("http://www.example.com/playlist/summer-mix")
      expect(meta(html, "twitter:card")).to eq("summary_large_image")
    end

    it "points og:image at a real 1200x630 file" do
      png = Rails.public_path.join("social-playlist.png")
      expect(png).to exist
      expect(png.binread(24).unpack("x16N2")).to eq([ 1200, 630 ]) # width/height from the PNG header
    end

    it "still shows song titles on the page itself" do
      get playlist_path(playlist.slug)
      expect(response.body).to include("A Band - First").and include("B Band - Second")
    end
  end
end
