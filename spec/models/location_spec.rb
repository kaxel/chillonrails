require 'rails_helper'

RSpec.describe Location, type: :model do
  describe "validations" do
    it "is valid with a name" do
      expect(build(:location)).to be_valid
    end

    it "requires a name" do
      expect(build(:location, name: nil)).not_to be_valid
    end

    it "requires a unique name" do
      create(:location, name: "Los Angeles")
      expect(build(:location, name: "Los Angeles")).not_to be_valid
    end

    it "requires a unique slug" do
      create(:location, name: "Los Angeles")
      duplicate = build(:location, name: "Los Angeles ")
      duplicate.valid?
      # Both parameterize to "los-angeles"
      expect(duplicate.errors[:slug]).to be_present
    end
  end

  describe "slug generation" do
    it "generates a slug from the name before validation" do
      location = build(:location, name: "New York City", slug: nil)
      location.valid?
      expect(location.slug).to eq("new-york-city")
    end

    it "overwrites the slug based on the current name" do
      location = build(:location, name: "San Diego", slug: "old-slug")
      location.valid?
      expect(location.slug).to eq("san-diego")
    end
  end
end
