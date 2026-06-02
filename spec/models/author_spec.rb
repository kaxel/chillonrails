require 'rails_helper'

RSpec.describe Author, type: :model do
  describe "validations" do
    it "is valid with a name and slug" do
      expect(build(:author)).to be_valid
    end

    it "requires a name" do
      expect(build(:author, name: nil)).not_to be_valid
    end

    it "requires a slug" do
      expect(build(:author, slug: nil)).not_to be_valid
    end

    it "requires a unique slug" do
      create(:author, slug: "taken")
      expect(build(:author, slug: "taken")).not_to be_valid
    end

    it "allows a blank item_id" do
      create(:author, item_id: nil)
      expect(build(:author, item_id: nil)).to be_valid
    end

    it "requires a unique item_id when present" do
      create(:author, item_id: "abc123")
      expect(build(:author, item_id: "abc123")).not_to be_valid
    end
  end

  describe "scopes" do
    it ".published returns only non-draft authors" do
      published = create(:author, draft: false)
      create(:author, draft: true)
      expect(Author.published).to contain_exactly(published)
    end

    it ".editorial_chiefs returns only editorial chiefs" do
      chief = create(:author, editorial_chief: true)
      create(:author, editorial_chief: false)
      expect(Author.editorial_chiefs).to contain_exactly(chief)
    end

    it ".by_location filters by location" do
      la = create(:author, location: "los-angeles")
      create(:author, location: "new-york")
      expect(Author.by_location("los-angeles")).to contain_exactly(la)
    end
  end

  describe "#display_name" do
    it "returns the name" do
      author = build(:author, name: "Jane Doe")
      expect(author.display_name).to eq("Jane Doe")
    end
  end

  describe "#social_links" do
    it "returns only present social profile links" do
      author = build(:author,
        social_profile_link_1: "https://a.com",
        social_profile_link_2: "",
        social_profile_link_3: "https://c.com")
      expect(author.social_links).to eq([ "https://a.com", "https://c.com" ])
    end

    it "returns an empty array when none are set" do
      author = build(:author)
      expect(author.social_links).to eq([])
    end
  end

  describe "#locations_from_hash" do
    it "titleizes semicolon-delimited locations" do
      author = build(:author, location: "los angeles;new york")
      expect(author.locations_from_hash).to eq([ "Los Angeles", "New York" ])
    end

    it "normalizes Usa to USA and Uk to UK" do
      author = build(:author, location: "usa;uk")
      expect(author.locations_from_hash).to eq([ "USA", "UK" ])
    end
  end
end
