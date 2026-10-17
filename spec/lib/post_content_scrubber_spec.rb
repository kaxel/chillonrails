require "rails_helper"

RSpec.describe PostContentScrubber do
  def scrub(html)
    ActionController::Base.helpers.sanitize(html, scrubber: described_class.new)
  end

  let(:bandcamp) do
    '<iframe style="border: 0; width: 100%; height: 120px;" src="https://bandcamp.com/EmbeddedPlayer/track=1234567890/size=large/bgcol=ffffff/linkcol=0687f5/tracklist=false/artwork=small/transparent=true/" seamless>' \
      '<a href="https://artist.bandcamp.com/track/song">Song by Artist</a></iframe>'
  end

  it "keeps a Bandcamp embed with its sizing" do
    html = scrub(bandcamp)
    expect(html).to include('src="https://bandcamp.com/EmbeddedPlayer/track=1234567890/')
    expect(html).to include("height:120px")
  end

  it "keeps YouTube, Vimeo, Mixcloud, Spotify and Pannellum players" do
    %w[
      https://www.youtube.com/embed/CLCx5FyHG6w
      https://www.youtube-nocookie.com/embed/CLCx5FyHG6w
      https://player.vimeo.com/video/355598436?loop=false
      https://www.mixcloud.com/widget/iframe/?feed=%2Fchillfiltr%2Fshow%2F
      https://open.spotify.com/embed/track/1xZtyh6ZffZm8e1eKzyBC9
      https://cdn.pannellum.org/2.5/pannellum.htm#panorama=https%3A%2F%2Fres.cloudinary.com%2Fpano.jpg
    ].each do |src|
      expect(scrub(%(<iframe src="#{src}"></iframe>))).to include("<iframe"), src
    end
  end

  it "removes iframes from anywhere else, fallback content included" do
    html = scrub('<p>Hi</p><iframe src="https://evil.example/bandcamp.com/EmbeddedPlayer/"><a href="x">fallback</a></iframe>')
    expect(html).to eq("<p>Hi</p>")
  end

  it "removes iframes with no src or a javascript: src" do
    expect(scrub("<iframe></iframe>")).to eq("")
    expect(scrub('<iframe src="javascript:alert(1)"></iframe>')).to eq("")
  end

  it "still strips scripts and event handlers" do
    html = scrub('<p onclick="x()">Hi</p><script>alert(1)</script><iframe src="https://www.youtube.com/embed/abc" onload="x()"></iframe>')
    expect(html).not_to include("script")
    expect(html).not_to include("onclick")
    expect(html).not_to include("onload")
  end

  it "drops positioning styles so an embed can't cover the page" do
    html = scrub('<iframe src="https://player.vimeo.com/video/1" style="position:absolute;top:0;left:0;width:100%;height:100%;"></iframe>')
    expect(html).not_to include("position")
  end

  it "keeps the existing allowlist for regular content" do
    html = scrub('<p>A <a href="#" data-seek="10"><strong>song</strong></a></p><audio controls src="https://x.test/a.mp3"></audio>')
    expect(html).to include('data-seek="10"')
    expect(html).to include("<audio controls")
  end
end
