require "rails_helper"

RSpec.describe "Writing a post in the in-house editor", type: :request do
  # The app only allows one account to be an admin (see User#admin_email_restriction).
  let(:admin) { create(:user, :confirmed, email_address: "songlistrnet@gmail.com", admin: true) }
  let(:regular_user) { create(:user, :confirmed) }

  # Sign-in is Google/Apple only, so stand in for the session cookie lookup.
  def sign_in_as(user)
    session = create(:session, user: user)
    allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(session)
  end

  let(:valid_params) do
    {
      title: "Dusty Sequoia Returns",
      preview: "A new single from Eugene.",
      content: "<p>First paragraph.</p><p><br></p><h3>A heading</h3><p>Second <strong>bold</strong>.</p>",
      topic: "music",
      author: "krister-axel",
      tags: "indie-folk",
      location: "eugene;oregon",
      published_on: "2026-11-07"
    }
  end

  describe "access" do
    it "sends signed-out visitors to sign in" do
      get new_post_path
      expect(response).to redirect_to(new_session_path)

      post posts_path, params: { post: valid_params }
      expect(response).to redirect_to(new_session_path)
      expect(Post.count).to eq(0)
    end

    it "keeps signed-in non-admins out" do
      sign_in_as(regular_user)

      get new_post_path
      expect(response).to redirect_to(root_path)

      post posts_path, params: { post: valid_params }
      expect(response).to redirect_to(root_path)
      expect(Post.count).to eq(0)
    end

    it "shows admins the editor" do
      sign_in_as(admin)
      get new_post_path

      expect(response).to have_http_status(:success)
      html = Nokogiri::HTML(response.body)
      expect(html.at_css("trix-editor[input=post_content]")).to be_present
      expect(html.at_css('input[type=file][name="post[header_image]"]')).to be_present
      expect(html.at_css('input[name="post[published_on]"]')["value"]).to eq(Date.current.iso8601)
    end
  end

  describe "New post link in the header" do
    def new_post_link
      Nokogiri::HTML(response.body).at_css(%(header a[href="#{new_post_path}"]))
    end

    it "is shown to admins" do
      sign_in_as(admin)
      get authors_path
      expect(new_post_link).to be_present
    end

    it "is hidden from everyone else" do
      get authors_path
      expect(new_post_link).to be_nil

      sign_in_as(regular_user)
      get authors_path
      expect(new_post_link).to be_nil
    end
  end

  describe "publishing" do
    before { sign_in_as(admin) }

    it "creates the post, owned by the admin, and shows it" do
      post posts_path, params: { post: valid_params }

      created = Post.last
      expect(response).to redirect_to(post_path(created.slug))
      expect(created).to have_attributes(
        title: "Dusty Sequoia Returns", slug: "dusty-sequoia-returns", user: admin,
        topic: "music", published_on: Date.new(2026, 11, 7), created_on: Date.current
      )

      follow_redirect!
      expect(response.body).to include("Dusty Sequoia Returns")
    end

    it "stores the body cleaned up: no empty paragraphs" do
      post posts_path, params: { post: valid_params }
      expect(Post.last.content).to eq("<p>First paragraph.</p><h3>A heading</h3><p>Second <strong>bold</strong>.</p>")
    end

    # What Trix actually submits for an "Insert embed": a placeholder figure,
    # with the embed code only in the attachment's JSON.
    def embed_figure(iframe_html)
      json = { content: '<span class="post-embed-card">▶ Bandcamp player</span>', embed: iframe_html,
               contentType: "application/vnd.chillfiltr.embed" }.to_json
      %(<figure data-trix-attachment="#{ERB::Util.html_escape(json)}" data-trix-content-type="application/vnd.chillfiltr.embed" ) +
        %(class="attachment attachment--content"><figcaption class="attachment__caption"></figcaption></figure>)
    end

    it "puts the real player in place of each embed placeholder and drops untrusted ones" do
      bandcamp = '<iframe style="border: 0; width: 100%; height: 120px;" src="https://bandcamp.com/EmbeddedPlayer/track=123/size=large/" seamless>' \
                 '<a href="https://artist.bandcamp.com/track/song">Song by Artist</a></iframe>'
      content = "<p>Listen:#{embed_figure(bandcamp)}</p>" \
                "<p>Also:#{embed_figure('<iframe src="https://evil.example/x"></iframe>')}</p><script>alert(1)</script>"
      post posts_path, params: { post: valid_params.merge(content: content) }

      stored = Post.last.content
      expect(stored).to start_with('<p>Listen:</p><iframe style="border:0;width:100%;height:120px;" src="https://bandcamp.com/EmbeddedPlayer/track=123/size=large/"')
      expect(stored).to end_with("<p>Also:</p>")
      %w[figure data-trix post-embed-card evil.example script].each { |gone| expect(stored).not_to include(gone) }
    end

    it "keeps text typed after an embed in its own paragraph" do
      bandcamp = '<iframe src="https://bandcamp.com/EmbeddedPlayer/track=123/"></iframe>'
      content = "<p>Listen:#{embed_figure(bandcamp)}And <strong>after</strong> it.</p><p>Next.</p>"
      post posts_path, params: { post: valid_params.merge(content: content) }

      expect(Post.last.content).to eq(
        '<p>Listen:</p><iframe src="https://bandcamp.com/EmbeddedPlayer/track=123/"></iframe>' \
        "<p>And <strong>after</strong> it.</p><p>Next.</p>"
      )
    end

    it "uses an uploaded header image as the post image" do
      image = fixture_file_upload("header.png", "image/png")
      post posts_path, params: { post: valid_params.merge(header_image: image) }

      created = Post.last
      expect(created.header_image).to be_attached
      expect(created.image).to start_with("/rails/active_storage/blobs/")
      expect(created.image).to end_with("/header.png")
    end

    it "rejects a header image that isn't a web image" do
      file = fixture_file_upload("sample.mp3", "audio/mpeg")
      post posts_path, params: { post: valid_params.merge(header_image: file) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must be a JPEG, PNG, WebP, or GIF image")
      expect(Post.count).to eq(0)
    end

    it "shows what to fix when the post is incomplete" do
      post posts_path, params: { post: valid_params.merge(title: "", content: "") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Title can&#39;t be blank")
      expect(Post.count).to eq(0)
    end

    it "offers Unknown as an author, shown like older anonymous posts" do
      get new_post_path
      expect(Nokogiri::HTML(response.body).at_css('select[name="post[author]"] option[value="unknown"]').text).to eq("Unknown")

      post posts_path, params: { post: valid_params.merge(author: "unknown") }
      follow_redirect!
      expect(response.body).to include("by Unknown")
    end

    it "makes a plain-text subtitle from the body when none is given" do
      post posts_path, params: { post: valid_params.merge(preview: "") }
      expect(Post.last.preview).to eq("First paragraph. A heading Second bold.")
    end
  end
end
