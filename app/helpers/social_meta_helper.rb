# Open Graph / Twitter card values for link previews (iMessage, Facebook,
# Slack, etc.). Scrapers need absolute URLs and can't use SVG images.
module SocialMetaHelper
  DEFAULT_SOCIAL_IMAGE = "/logo-900-clear.png".freeze
  # Weekly Catch posts use a per-episode pixel-fish SVG as their image. Scrapers can't use SVG, so
  # each one has a 1200x630 PNG twin (written by spinitscrape's social_image.py).
  WEEKLY_CATCH_FISH = %r{\A/weekly-catch-fish/(\d{4}-\d{2}-\d{2})\.svg\z}
  DEFAULT_DESCRIPTION = "CHILLFILTR® - Discover the latest content and updates".freeze

  def social_image_url(path)
    path = weekly_catch_og_path(path) || path
    path = DEFAULT_SOCIAL_IMAGE if path.blank? || File.extname(URI.parse(path).path.to_s).casecmp?(".svg")
    URI.join("#{request.base_url}/", path).to_s
  rescue URI::InvalidURIError
    URI.join("#{request.base_url}/", DEFAULT_SOCIAL_IMAGE).to_s
  end

  def weekly_catch_og_path(path)
    date = path.to_s[WEEKLY_CATCH_FISH, 1]
    png = "/weekly-catch-og/#{date}.png" if date
    png if png && Rails.public_path.join(png.delete_prefix("/")).exist?
  end

  def social_description(text)
    strip_tags(text.to_s).squish.truncate(200).presence || DEFAULT_DESCRIPTION
  end
end
