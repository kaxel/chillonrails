require 'rails_helper'

RSpec.describe PageNotFound, type: :model do
  it "is valid with a url and accessed_at" do
    expect(build(:page_not_found)).to be_valid
  end

  it "persists the url and accessed_at it was created with" do
    time = Time.zone.parse("2026-01-15 10:30:00")
    record = PageNotFound.create!(url: "/missing-page", accessed_at: time)

    expect(record.reload.url).to eq("/missing-page")
    expect(record.reload.accessed_at).to eq(time)
  end

  it "has no attribute constraints, so ErrorsController#not_found's bare .create never fails" do
    expect(PageNotFound.create(url: nil, accessed_at: nil)).to be_persisted
  end
end
