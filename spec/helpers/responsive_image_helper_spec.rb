require 'rails_helper'

RSpec.describe ResponsiveImageHelper, type: :helper do
  describe "#optimize_image_url" do
    it "returns blank urls unchanged" do
      expect(helper.optimize_image_url("")).to eq("")
    end

    it "appends width and quality with ? when no query string exists" do
      expect(helper.optimize_image_url("https://img/photo.jpg")).to eq("https://img/photo.jpg?w=1024&q=80")
    end

    it "appends with & when a query string already exists" do
      expect(helper.optimize_image_url("https://img/photo.jpg?v=2")).to eq("https://img/photo.jpg?v=2&w=1024&q=80")
    end

    it "honors custom width and quality" do
      expect(helper.optimize_image_url("https://img/photo.jpg", width: 640, quality: 75))
        .to eq("https://img/photo.jpg?w=640&q=75")
    end
  end

  describe "#picture_srcset" do
    it "returns an empty string for a blank url" do
      expect(helper.picture_srcset(nil)).to eq("")
    end

    it "generates 1x and 2x sources for the chosen preset" do
      result = helper.picture_srcset("https://img/photo.jpg", :small)
      expect(result).to eq(
        "https://img/photo.jpg?w=640&q=75 1x, https://img/photo.jpg?w=1280&q=75 2x"
      )
    end

    it "falls back to the medium preset for an unknown preset" do
      result = helper.picture_srcset("https://img/photo.jpg", :enormous)
      expect(result).to eq(
        "https://img/photo.jpg?w=1024&q=80 1x, https://img/photo.jpg?w=2048&q=80 2x"
      )
    end
  end

  describe "#image_loading_placeholder" do
    it "returns an inline svg data uri" do
      expect(helper.image_loading_placeholder).to start_with("data:image/svg+xml,")
    end
  end
end
