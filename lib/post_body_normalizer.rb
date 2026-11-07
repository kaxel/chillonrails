# Cleans the HTML the in-house editor (Trix) submits for a post body so it is
# stored in the same shape as every other post: embed players are unwrapped
# from Trix's attachment <figure>, Trix's data attributes are removed, empty
# paragraphs are dropped, and the result goes through PostContentScrubber —
# so what's stored is exactly what the post page will show.
module PostBodyNormalizer
  module_function

  def call(html)
    doc = Nokogiri::HTML5.fragment(html.to_s)

    doc.css("figure[data-trix-attachment]").each do |figure|
      embed = figure.at_css("iframe")
      embed ? figure.replace(embed) : figure.remove
    end
    doc.css("*").each do |node|
      node.attribute_nodes.each { |attr| attr.remove if attr.name.start_with?("data-trix") }
    end
    doc.css("p").each do |p|
      p.remove if p.text.strip.empty? && p.css("img, iframe, audio").empty?
    end

    ActionController::Base.helpers.sanitize(doc.to_html, scrubber: PostContentScrubber.new).strip
  end
end
