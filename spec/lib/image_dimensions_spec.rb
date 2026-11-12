require "rails_helper"

RSpec.describe ImageDimensions do
  def fixture(name) = Rails.root.join("spec/fixtures/files", name)

  it "reads PNG, JPEG, and GIF sizes" do
    expect(described_class.read(fixture("header.png")).to_a).to eq([ "image/png", 12, 8 ])
    expect(described_class.read(fixture("header.jpg")).to_a).to eq([ "image/jpeg", 12, 8 ])
    expect(described_class.read(fixture("header.gif")).to_a).to eq([ "image/gif", 12, 8 ])
  end

  it "reads lossless and extended WebP sizes" do
    # VP8L: 14-bit width-1 and height-1 packed after the 0x2F signature.
    bits = (1200 - 1) | ((630 - 1) << 14)
    lossless = "RIFF....WEBPVP8L....\x2F".b + [ bits ].pack("V") + "\x00" * 8
    expect(described_class.from_io(StringIO.new(lossless)).to_a).to eq([ "image/webp", 1200, 630 ])

    # VP8X: 24-bit width-1 and height-1 at bytes 24 and 27.
    extended = "RIFF....WEBPVP8X........".b + [ 1199, 629 ].pack("VV").bytes.values_at(0, 1, 2, 4, 5, 6).pack("C*")
    expect(described_class.from_io(StringIO.new(extended)).to_a).to eq([ "image/webp", 1200, 630 ])
  end

  it "returns nil for missing files and non-images" do
    expect(described_class.read(fixture("nope.png"))).to be_nil
    expect(described_class.read(fixture("sample.mp3"))).to be_nil
  end
end
