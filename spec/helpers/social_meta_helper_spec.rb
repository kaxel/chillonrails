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
end
