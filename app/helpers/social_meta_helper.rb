# Open Graph / Twitter card values for link previews (iMessage, Facebook,
# Slack, etc.). Scrapers need absolute URLs and can't use SVG images.
module SocialMetaHelper
  DEFAULT_SOCIAL_IMAGE = "/logo-900-clear.png".freeze
  DEFAULT_DESCRIPTION = "CHILLFILTR® - Discover the latest content and updates".freeze

  def social_image_url(path)
    path = DEFAULT_SOCIAL_IMAGE if path.blank? || File.extname(URI.parse(path).path.to_s).casecmp?(".svg")
    URI.join("#{request.base_url}/", path).to_s
  rescue URI::InvalidURIError
    URI.join("#{request.base_url}/", DEFAULT_SOCIAL_IMAGE).to_s
  end

  def social_description(text)
    strip_tags(text.to_s).squish.truncate(200).presence || DEFAULT_DESCRIPTION
  end
end
