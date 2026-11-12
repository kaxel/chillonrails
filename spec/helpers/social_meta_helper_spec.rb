require "rails_helper"

RSpec.describe SocialMetaHelper, type: :helper do
  before { allow(helper.request).to receive(:base_url).and_return("https://chillfiltr.com") }

  describe "#social_image_url" do
    it "falls back to the logo for a blank image" do
      expect(helper.social_image_url(nil)).to eq("https://chillfiltr.com/logo-900-clear.png")
    end

    it "falls back to the logo for an SVG (scrapers can't use them)" do
      expect(helper.social_image_url("/icon.svg")).to eq("https://chillfiltr.com/logo-900-clear.png")
    end

    it "makes relative raster paths absolute" do
      expect(helper.social_image_url("/some/pic.jpg")).to eq("https://chillfiltr.com/some/pic.jpg")
    end

    it "uses the PNG twin of a Weekly Catch fish SVG when it exists" do
      expect(helper.social_image_url("/weekly-catch-fish/2026-09-16.svg"))
        .to eq("https://chillfiltr.com/weekly-catch-og/2026-09-16.png")
    end

    it "falls back to the logo for a Weekly Catch fish with no PNG twin" do
      expect(helper.social_image_url("/weekly-catch-fish/1999-01-01.svg"))
        .to eq("https://chillfiltr.com/logo-900-clear.png")
    end
  end

  describe "#social_image_info" do
    it "reads the type and size of an image served from public/" do
      expect(helper.social_image_info("https://chillfiltr.com/logo-900-clear.png").to_a).to eq([ "image/png", 900, 1023 ])
    end

    it "gives the type of an uploaded header image" do
      blob = ActiveStorage::Blob.create_and_upload!(io: Rails.root.join("spec/fixtures/files/header.png").open,
                                                    filename: "header.png", content_type: "image/png")
      url = "https://chillfiltr.com#{Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)}"
      expect(helper.social_image_info(url).to_a).to eq([ "image/png", nil, nil ])
    end

    it "knows nothing about other sites' images, missing files, or paths outside public/" do
      expect(helper.social_image_info("https://cdn.example.com/logo-900-clear.png")).to be_nil
      expect(helper.social_image_info("https://chillfiltr.com/nope.jpg")).to be_nil
      expect(helper.social_image_info("https://chillfiltr.com/../config/database.yml")).to be_nil
    end
  end

  describe "#playlist_social_description" do
    def playlist_with(count)
      songs = (1..count).to_h { |n| [ n.to_s, "https://x.test/Artist - Song #{n}.mp3" ] }
      build(:playlist, songs: songs)
    end

    it "counts the songs and names the first few" do
      expect(helper.playlist_social_description(playlist_with(6)))
        .to eq("6 songs: Artist - Song 1, Artist - Song 2, Artist - Song 3, Artist - Song 4, and more.")
    end

    it "doesn't say 'and more' when everything is already listed" do
      expect(helper.playlist_social_description(playlist_with(2))).to eq("2 songs: Artist - Song 1, Artist - Song 2.")
    end

    it "uses the singular for one song" do
      expect(helper.playlist_social_description(playlist_with(1))).to eq("1 song: Artist - Song 1.")
    end

    it "falls back to the site description for an empty playlist" do
      expect(helper.playlist_social_description(playlist_with(0))).to eq(SocialMetaHelper::DEFAULT_DESCRIPTION)
    end

    it "stays within a preview-friendly length" do
      long = build(:playlist, songs: (1..9).to_h { |n| [ n.to_s, "https://x.test/#{"Very Long Artist Name " * 4} - Title #{n}.mp3" ] })
      expect(helper.playlist_social_description(long).length).to be <= 200
    end
  end
end
