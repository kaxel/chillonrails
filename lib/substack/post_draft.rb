module Substack
  # Builds the Substack version of a Post: title, subtitle and a ProseMirror
  # body (featured image, video/audio, content, and a link back to
  # chillfiltr.com). The same body renders to HTML for the paste fallback.
  class PostDraft
    SITE_URL = "https://chillfiltr.com".freeze

    attr_reader :post

    def initialize(post, image_resolver: ->(src) { src })
      @post = post
      @converter = HtmlConverter.new(base_url: SITE_URL, image_resolver: image_resolver)
    end

    delegate :title, to: :post

    def subtitle
      ActionController::Base.helpers.strip_tags(post.preview.to_s).squish.truncate(250)
    end

    def canonical_url
      "#{SITE_URL}/post/#{post.slug}"
    end

    def body
      @body ||= { type: "doc", content: nodes }
    end

    def to_html
      HtmlRenderer.new.render(body[:content])
    end

    private

    def nodes
      result = []
      result << @converter.image_node(post.image, alt: post.title) if post.image.present?
      result << video_node if post.video_link.present?
      result << audio_node if post.audio_link.present?
      result.concat(@converter.convert(post.content))
      result << { type: "horizontal_rule" }
      result << @converter.paragraph([
        @converter.text("Originally published on ", [ { type: "em" } ]),
        @converter.text("chillfiltr.com", [ { type: "em" }, @converter.link_mark(canonical_url) ])
      ])
      result.compact
    end

    def audio_node
      label = post.audio_embed_url.present? ? "▶ Listen on Bandcamp" : "▶ Listen to the audio"
      @converter.link_paragraph(label, post.audio_link)
    end

    def video_node
      link = post.video_link
      if (id = HtmlConverter.youtube_id(link))
        { type: "youtube2", attrs: { videoId: id, startTime: nil, endTime: nil } }
      elsif link.include?("mixcloud")
        @converter.link_paragraph("▶ Listen on Mixcloud", link)
      elsif link.include?("vimeo")
        @converter.link_paragraph("▶ Watch on Vimeo", link)
      else
        @converter.link_paragraph("▶ Watch the video", link)
      end
    end
  end
end
