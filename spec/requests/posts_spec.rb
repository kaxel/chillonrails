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

    describe "link preview tags" do
      def meta(html, property)
        html.at_css(%(meta[property="#{property}"]))&.[]("content")
      end

      let(:post) do
        create(:post, title: "Stella & OpenAI", slug: "stella-and-openai", tags: "commentary", author: "krister-axel",
          published_on: Date.new(2026, 10, 10), preview: "<p>You're supposed to know how you got there.</p>",
          image: "/images/posts/stella/main.jpg")
      end

      it "gives scrapers a title, description, absolute image and canonical URL" do
        get post_path(slug: post.slug)
        html = Nokogiri::HTML(response.body)

        expect(html.at_css("title").text).to eq("Stella & OpenAI — CHILLFILTR®")
        expect(meta(html, "og:title")).to eq("Stella & OpenAI")
        expect(meta(html, "og:type")).to eq("article")
        expect(meta(html, "og:description")).to eq("You're supposed to know how you got there.")
        expect(meta(html, "og:image")).to eq("http://www.example.com/images/posts/stella/main.jpg")
        expect(meta(html, "og:url")).to eq("http://www.example.com/post/stella-and-openai")
        expect(html.css('meta[name="description"]').size).to eq(1)
      end

      it "falls back to the site logo when the post has no image or an SVG" do
        post.update!(image: "/weekly-catch-fish/2026-10-07.svg")
        get post_path(slug: post.slug)
        expect(meta(Nokogiri::HTML(response.body), "og:image")).to eq("http://www.example.com/logo-900-clear.png")

        post.update!(image: nil)
        get post_path(slug: post.slug)
        expect(meta(Nokogiri::HTML(response.body), "og:image")).to eq("http://www.example.com/logo-900-clear.png")
      end

      it "keeps an external image URL as-is" do
        post.update!(image: "https://cdn.example.com/cover.jpg")
        get post_path(slug: post.slug)
        expect(meta(Nokogiri::HTML(response.body), "og:image")).to eq("https://cdn.example.com/cover.jpg")
      end
    end
  end
end
