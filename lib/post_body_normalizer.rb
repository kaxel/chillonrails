# Cleans the HTML the in-house editor (Trix) submits for a post body so it is
# stored in the same shape as every other post: embed players replace the
# placeholder <figure> Trix submits for them, Trix's data attributes are
# removed, empty paragraphs are dropped, and the result goes through
# PostContentScrubber — so what's stored is exactly what the post page shows.
module PostBodyNormalizer
  module_function

  def call(html)
    doc = Nokogiri::HTML5.fragment(html.to_s)
    doc.css("script, style").remove # the scrubber would drop the tags but keep their text

    doc.css("figure[data-trix-attachment]").each do |figure|
      embed = embed_code(figure)
      embed ? figure.replace(Nokogiri::HTML5.fragment(embed)) : figure.remove
    end
    wrap_loose_inline_content(doc)
    doc.css("*").each do |node|
      node.attribute_nodes.each { |attr| attr.remove if attr.name.start_with?("data-trix") }
    end
    doc.css("p").each do |p|
      p.remove if p.text.strip.empty? && p.css("img, iframe, audio").empty?
    end

    ActionController::Base.helpers.sanitize(doc.to_html, scrubber: PostContentScrubber.new).strip
  end

  BLOCK_TAGS = %w[p h1 h2 h3 h4 h5 h6 ul ol blockquote iframe audio img figure div pre hr].freeze

  # Trix keeps an embed inline in its paragraph, and HTML closes a <p> when a
  # player starts, so text typed after an embed can end up outside any <p>.
  # Gather such top-level text and inline elements into paragraphs.
  def wrap_loose_inline_content(doc)
    run = []
    flush = lambda do
      if run.any? { |n| n.element? || n.text.strip.present? }
        p = doc.document.create_element("p")
        run.first.add_previous_sibling(p)
        run.each { |n| p.add_child(n) }
      end
      run = []
    end
    doc.children.to_a.each do |node|
      node.element? && BLOCK_TAGS.include?(node.name) ? flush.call : run << node
    end
    flush.call
  end

  # The editor shows a placeholder card for an embed and carries the player's
  # embed code in the attachment's JSON (`embed`); Trix doesn't keep iframes in
  # the figure itself. Untrusted players are removed by PostContentScrubber.
  def embed_code(figure)
    JSON.parse(figure["data-trix-attachment"].to_s)["embed"].presence
  rescue JSON::ParserError
    nil
  end
end
