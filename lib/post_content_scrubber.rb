# Sanitizes post content for the post page. Same allowlist as before, plus
# <iframe> — but only for embed players we trust (Bandcamp, YouTube, Vimeo,
# Mixcloud, Spotify). Any other iframe is removed entirely, fallback content and all.
class PostContentScrubber < Rails::HTML::PermitScrubber
  TAGS = %w[p br strong em ul ol li h1 h2 h3 h4 h5 h6 blockquote a img audio iframe].freeze
  ATTRIBUTES = %w[href src alt class data-seek controls controlslist preload
                  width height style title allow allowfullscreen frameborder scrolling seamless].freeze

  EMBED_SOURCES = [
    %r{\Ahttps://bandcamp\.com/EmbeddedPlayer/},
    %r{\Ahttps://(www\.)?youtube(-nocookie)?\.com/embed/},
    %r{\Ahttps://player\.vimeo\.com/video/},
    %r{\Ahttps://(www\.|player-widget\.)?mixcloud\.com/widget/},
    %r{\Ahttps://open\.spotify\.com/embed/}
  ].freeze

  def self.trusted_embed?(src)
    src = src.to_s.strip
    src = "https:#{src}" if src.start_with?("//")
    EMBED_SOURCES.any? { |pattern| pattern.match?(src) }
  end

  def initialize
    super
    self.tags = TAGS
    self.attributes = ATTRIBUTES
  end

  def scrub(node)
    if node.element? && node.name == "iframe" && !self.class.trusted_embed?(node["src"])
      node.remove
      return STOP
    end
    super
  end
end
