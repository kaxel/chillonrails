require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#get_val_string" do
    it "extracts the id from a youtu.be link" do
      expect(helper.get_val_string("https://youtu.be/sVCX9f-fhMc")).to eq("sVCX9f-fhMc")
    end

    it "extracts the v param from a watch?v= link" do
      expect(helper.get_val_string("https://www.youtube.com/watch?v=tAMNPeo7AG0")).to eq("tAMNPeo7AG0")
    end

    it "extracts the id from a vimeo link" do
      expect(helper.get_val_string("https://vimeo.com/123456")).to eq("123456")
    end
  end

  describe "#shorten" do
    it "leaves short strings untouched" do
      expect(helper.shorten("short")).to eq("short")
    end

    it "truncates long strings to 60 characters plus ellipsis" do
      result = helper.shorten("a" * 100)
      expect(result).to eq(("a" * 60) + "...")
    end
  end

  describe "#author_photo" do
    it "returns the krister-axel thumbnail for krister-axel" do
      expect(helper.author_photo("krister-axel")).to include("krister-axel-thumb")
    end

    it "returns the default logo for other authors" do
      expect(helper.author_photo("someone-else")).to include("new-logo--chillfiltr")
    end
  end

  describe "#pretty_author" do
    it "capitalizes and joins hyphenated names" do
      expect(helper.pretty_author("krister-axel")).to eq("Krister Axel ")
    end

    it "capitalizes a single name" do
      expect(helper.pretty_author("krister")).to eq("Krister")
    end
  end

  describe "#get_topic_color" do
    it "maps known topics to colors" do
      expect(helper.get_topic_color("music")).to eq("bg-cyan-600")
      expect(helper.get_topic_color("poetry")).to eq("bg-pink-600")
    end

    it "returns nil for unknown topics" do
      expect(helper.get_topic_color("unknown")).to be_nil
    end
  end

  describe "color helpers" do
    it "#get_location_color returns a known background color" do
      expect(ApplicationHelper::LIGHT_COLOR_BG).to include(helper.get_location_color)
    end

    it "#get_tag_color returns a known background color" do
      expect(ApplicationHelper::LIGHT_COLOR_BG).to include(helper.get_tag_color)
    end
  end

  describe "#random_search_message" do
    it "returns a non-empty string" do
      expect(helper.random_search_message).to be_a(String).and be_present
    end
  end
end
