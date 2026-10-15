require 'rails_helper'

RSpec.describe "Posts", type: :request do
  describe "GET /post/:slug" do
    # Older posts (e.g. Indie Music on Tap season 1) embed native <audio>
    # players directly in their content. The show page sanitizes content with
    # an explicit allowlist, so these silently vanished until audio was added.
    it "renders native audio players embedded in post content" do
      post = create(:post, tags: "indie music on tap", author: "krister-axel", published_on: Date.new(2019, 6, 10), content: <<~HTML)
        <p>Episode 1</p>
        <audio class="js-player" id="ep1" controls controlsList="nodownload" src="https://res.cloudinary.com/example/ep1.mp3"></audio>
      HTML

      get post_path(slug: post.slug)

      expect(response).to have_http_status(:success)
      html = Nokogiri::HTML(response.body)
      audio = html.at_css(".content audio")
      expect(audio).to be_present
      expect(audio["src"]).to eq("https://res.cloudinary.com/example/ep1.mp3")
      expect(audio).to have_attribute("controls")
      expect(audio["controlslist"]).to eq("nodownload")
    end

    it "still strips scripts, event handlers and javascript: audio sources" do
      post = create(:post, tags: "indie music on tap", author: "krister-axel", published_on: Date.new(2019, 6, 10), content: <<~HTML)
        <script>alert(1)</script>
        <audio controls src="javascript:alert(1)" onerror="alert(2)"></audio>
      HTML

      get post_path(slug: post.slug)

      body = Nokogiri::HTML(response.body).at_css(".content").to_html
      expect(body).not_to include("<script")
      expect(body).not_to include("onerror")
      expect(body).not_to include("javascript:")
    end
  end
end
