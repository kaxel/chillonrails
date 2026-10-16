require "rails_helper"

RSpec.describe Substack::PostDraft do
  let(:post) do
    build(:post,
      title: "Hello Substack",
      slug: "hello-substack",
      preview: "A <b>short</b> preview.",
      image: "/images/posts/hello/main.jpg",
      video_link: "https://www.youtube.com/watch?v=tAMNPeo7AG0",
      content: <<~HTML)
        <p>Intro with <strong>bold</strong>, <em>italic</em> and a <a href="/post/other">relative link</a>.</p>
        <h3>A heading</h3>
        <ol><li><a href="#" data-seek="10"><strong>Artist</strong> — Song</a></li></ol>
        <p>Before<br>after <img src="https://example.com/inline.png" alt="inline"></p>
        <audio controls><source src="https://example.com/a.mp3"></audio>
        loose text
      HTML
  end

  subject(:draft) { described_class.new(post) }

  let(:types) { draft.body[:content].map { |n| n[:type] } }

  it "builds a ProseMirror doc in reading order" do
    expect(draft.body[:type]).to eq("doc")
    expect(types).to eq(%w[captionedImage youtube2 paragraph heading ordered_list paragraph captionedImage paragraph paragraph horizontal_rule paragraph])
  end

  it "makes the featured image absolute" do
    expect(draft.body[:content].first.dig(:content, 0, :attrs, :src)).to eq("https://chillfiltr.com/images/posts/hello/main.jpg")
  end

  it "keeps marks and resolves relative links" do
    intro = draft.body[:content][2][:content]
    expect(intro).to include(a_hash_including(text: "bold", marks: [ { type: "strong" } ]))
    expect(intro).to include(a_hash_including(text: "relative link", marks: [ { type: "link", attrs: { href: "https://chillfiltr.com/post/other" } } ]))
  end

  it "drops seek-only '#' links but keeps their text" do
    item_para = draft.body[:content][4].dig(:content, 0, :content, 0)
    expect(item_para[:content].first).to eq(type: "text", text: "Artist", marks: [ { type: "strong" } ])
  end

  it "converts <br> to hard breaks and audio to a link" do
    expect(draft.body[:content][5][:content].map { |n| n[:type] }).to eq(%w[text hard_break text])
    expect(draft.body[:content][7].dig(:content, 0, :marks, 0, :attrs, :href)).to eq("https://example.com/a.mp3")
  end

  it "ends with a link back to chillfiltr.com" do
    link = draft.body[:content].last[:content].last[:marks].last
    expect(link).to eq(type: "link", attrs: { href: "https://chillfiltr.com/post/hello-substack" })
  end

  it "uses a plain-text subtitle" do
    expect(draft.subtitle).to eq("A short preview.")
  end

  it "skips SVG images, which Substack can't display" do
    post.image = "/weekly-catch-fish/2026-10-07.svg"
    expect(types.first).to eq("youtube2")
  end

  it "passes images through the resolver" do
    draft = described_class.new(post, image_resolver: ->(src) { "https://cdn.test/#{File.basename(src)}" })
    expect(draft.body[:content].first.dig(:content, 0, :attrs, :src)).to eq("https://cdn.test/main.jpg")
  end

  it "links non-YouTube video instead of embedding" do
    post.video_link = "https://www.mixcloud.com/chillfiltr/show/"
    expect(draft.body[:content][1].dig(:content, 0, :text)).to eq("▶ Listen on Mixcloud")
  end

  describe "#to_html" do
    it "renders paste-ready, escaped HTML" do
      post.content = "<p>Tom &amp; Jerry <em><a href=\"https://x.test\">here</a></em></p>"
      html = draft.to_html
      expect(html).to include('<p>Tom &amp; Jerry <em><a href="https://x.test">here</a></em></p>')
      expect(html).to include('<img src="https://chillfiltr.com/images/posts/hello/main.jpg" alt="Hello Substack">')
      expect(html).to include('<a href="https://www.youtube.com/watch?v=tAMNPeo7AG0">')
    end
  end
end
