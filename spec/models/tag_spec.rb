require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe "validations" do
    it "is valid with a name" do
      expect(build(:tag)).to be_valid
    end

    it "requires a name" do
      expect(build(:tag, name: nil)).not_to be_valid
    end

    it "requires a unique name" do
      create(:tag, name: "Indie")
      expect(build(:tag, name: "Indie")).not_to be_valid
    end
  end

  describe "slug generation" do
    it "generates a slug from the name before validation" do
      tag = build(:tag, name: "Lo Fi Beats", slug: nil)
      tag.valid?
      expect(tag.slug).to eq("lo-fi-beats")
    end
  end
end
