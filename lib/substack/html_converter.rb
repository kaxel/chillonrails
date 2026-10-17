module Substack
  # Converts post HTML into the ProseMirror nodes Substack's editor stores
  # in a draft's `draft_body`. Only the subset of the schema our posts use is
  # covered; anything unrecognised is unwrapped and its children kept.
  class HtmlConverter
    INLINE_MARKS = {
      "strong" => "strong", "b" => "strong",
      "em" => "em", "i" => "em",
      "code" => "code",
      "s" => "strikethrough", "strike" => "strikethrough", "del" => "strikethrough"
    }.freeze

    BLOCK_TAGS = %w[p h1 h2 h3 h4 h5 h6 ul ol li blockquote hr img audio iframe div section article figure pre table].freeze

    def self.youtube_id(url)
      url.to_s[%r{(?:youtu\.be/|[?&]v=|/embed/|/shorts/)([\w-]{11})}, 1]
    end

    # base_url makes relative links/images absolute. image_resolver maps an
    # absolute image URL to the URL Substack should display (e.g. after
    # uploading it), or nil to drop the image.
    def initialize(base_url:, image_resolver: ->(src) { src })
      @base_url = base_url
      @image_resolver = image_resolver
    end

    def convert(html)
      blocks(Nokogiri::HTML5.fragment(html.to_s).children)
    end

    def image_node(src, alt: nil)
      return if src.blank?
      return if File.extname(URI.parse(src).path.to_s).casecmp?(".svg") # Substack can't display SVG

      resolved = @image_resolver.call(absolute_url(src))
      return if resolved.blank?

      {
        type: "captionedImage",
        content: [ {
          type: "image2",
          attrs: {
            src: resolved, fullscreen: nil, imageSize: nil, height: nil, width: nil,
            resizeWidth: nil, bytes: nil, alt: alt.presence, title: nil, type: nil,
            href: nil, belowTheFold: false, internalRedirect: nil
          }
        } ]
      }
    rescue URI::InvalidURIError
      nil
    end

    def link_paragraph(label, href)
      paragraph([ text(label, [ link_mark(href) ]) ])
    end

    def paragraph(inlines)
      { type: "paragraph", content: inlines }
    end

    def text(value, marks = [])
      node = { type: "text", text: value }
      node[:marks] = marks if marks.any?
      node
    end

    def link_mark(href)
      { type: "link", attrs: { href: href } }
    end

    def absolute_url(href)
      URI.join(@base_url + "/", href.to_s.strip).to_s
    rescue URI::InvalidURIError
      href
    end

    private

    # Walks sibling nodes, gathering runs of inline content into paragraphs
    # and emitting block elements as their own nodes.
    def blocks(nodes)
      result = []
      pending = []
      flush = lambda do
        para = build_paragraph(pending)
        result << para if para
        pending = []
      end

      nodes.each do |node|
        if node.element? && BLOCK_TAGS.include?(node.name)
          flush.call
          result.concat(block(node))
        else
          pending << node
        end
      end
      flush.call
      result
    end

    def block(node)
      case node.name
      when "p", "pre"
        # A <p> may wrap an <img>/<audio>; split those out as blocks.
        blocks(node.children)
      when /\Ah([1-6])\z/
        inlines = trim(inlines(node.children))
        inlines.any? ? [ { type: "heading", attrs: { level: $1.to_i }, content: inlines } ] : []
      when "ul", "ol"
        items = node.element_children.select { |c| c.name == "li" }.filter_map do |li|
          content = blocks(li.children)
          { type: "list_item", content: content } if content.any?
        end
        return [] if items.empty?

        list = { type: node.name == "ul" ? "bullet_list" : "ordered_list", content: items }
        list[:attrs] = { start: (node["start"] || 1).to_i, order: (node["start"] || 1).to_i } if node.name == "ol"
        [ list ]
      when "blockquote"
        content = blocks(node.children)
        content.any? ? [ { type: "blockquote", content: content } ] : []
      when "hr"
        [ { type: "horizontal_rule" } ]
      when "img"
        [ image_node(node["src"], alt: node["alt"]) ].compact
      when "audio"
        src = node["src"] || node.at_css("source")&.[]("src")
        src.present? ? [ link_paragraph("▶ Listen to the audio", absolute_url(src)) ] : []
      when "iframe"
        [ embed_node(node) ].compact
      else
        blocks(node.children)
      end
    end

    # Substack can't take arbitrary iframes, so players become a YouTube embed
    # or a "Listen on …" link to the public page rather than the raw player.
    def embed_node(iframe)
      src = iframe["src"].to_s.strip
      return if src.blank?

      if (id = self.class.youtube_id(src))
        { type: "youtube2", attrs: { videoId: id, startTime: nil, endTime: nil } }
      elsif src.include?("bandcamp.com/EmbeddedPlayer")
        link_paragraph("▶ Listen on Bandcamp", bandcamp_page_url(iframe) || src)
      elsif (path = src[%r{open\.spotify\.com/embed/(\w+/\w+)}, 1])
        link_paragraph("▶ Listen on Spotify", "https://open.spotify.com/#{path}")
      elsif (id = src[%r{player\.vimeo\.com/video/(\d+)}, 1])
        link_paragraph("▶ Watch on Vimeo", "https://vimeo.com/#{id}")
      elsif (feed = src[/[?&]feed=([^&]+)/, 1]) && src.include?("mixcloud.com")
        link_paragraph("▶ Listen on Mixcloud", "https://www.mixcloud.com#{CGI.unescape(feed)}")
      else
        link_paragraph(src, absolute_url(src))
      end
    end

    # Bandcamp's embed code carries a link to the track/album page as the
    # iframe's fallback content; the HTML5 parser keeps that as raw text.
    def bandcamp_page_url(iframe)
      Nokogiri::HTML5.fragment(iframe.inner_html.presence || iframe.text).at_css("a[href]")&.[]("href")
    end

    def build_paragraph(nodes)
      inlines = trim(inlines(nodes))
      paragraph(inlines) if inlines.any?
    end

    def inlines(nodes, marks = [])
      nodes.flat_map do |node|
        if node.text?
          value = node.text.gsub(/\s+/, " ")
          value.empty? ? [] : [ text(value, marks) ]
        elsif !node.element?
          []
        elsif node.name == "br"
          [ { type: "hard_break" } ]
        elsif (mark = INLINE_MARKS[node.name])
          inlines(node.children, marks + [ { type: mark } ])
        elsif node.name == "a"
          href = node["href"].to_s.strip
          linkable = href.present? && !href.start_with?("#", "javascript:")
          inlines(node.children, linkable ? marks + [ link_mark(absolute_url(href)) ] : marks)
        else
          inlines(node.children, marks)
        end
      end
    end

    # Strips leading/trailing whitespace and hard breaks from a paragraph.
    def trim(inlines)
      inlines = inlines.drop_while { |n| n[:type] == "hard_break" }
      inlines = inlines.reverse.drop_while { |n| n[:type] == "hard_break" }.reverse
      return [] if inlines.empty?

      first, last = inlines.first, inlines.last
      first[:text] = first[:text].lstrip if first[:type] == "text"
      last[:text] = last[:text].rstrip if last[:type] == "text"
      inlines.reject { |n| n[:type] == "text" && n[:text].empty? }
    end
  end
end
