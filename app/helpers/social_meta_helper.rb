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

  # Type and pixel size of a preview image served from public/, for the
  # og:image:type/width/height tags. Uploaded (Active Storage) images report
  # their type only. nil when unknown (e.g. an image on another site).
  def social_image_info(url)
    uri = URI.parse(url.to_s)
    return unless uri.host.nil? || url.to_s.start_with?("#{request.base_url}/")

    path = URI.decode_www_form_component(uri.path.to_s)
    if path.start_with?("/rails/active_storage/")
      type = social_image_blob(path)&.content_type
      return type && ImageDimensions::Info.new(type, nil, nil)
    end

    file = Rails.public_path.join(path.delete_prefix("/")).expand_path
    return unless file.to_s.start_with?("#{Rails.public_path}/") && file.file?

    SocialMetaHelper.image_info_cache.fetch([ file.to_s, file.mtime.to_i ]) do |key|
      SocialMetaHelper.image_info_cache[key] = ImageDimensions.read(file)
    end
  rescue URI::InvalidURIError, ArgumentError
    nil
  end

  # Image headers don't change while a file's mtime stays the same.
  def self.image_info_cache
    @image_info_cache ||= Concurrent::Map.new
  end

  def social_image_blob(path)
    signed_id = path.split("/")[-2]
    ActiveStorage::Blob.find_signed(signed_id)
  end

  def weekly_catch_og_path(path)
    date = path.to_s[WEEKLY_CATCH_FISH, 1]
    png = "/weekly-catch-og/#{date}.png" if date
    png if png && Rails.public_path.join(png.delete_prefix("/")).exist?
  end

  # "6 songs: Down Like Silver - Broken Coastline, Krister Axel - As Good As Love, and more."
  def playlist_social_description(playlist)
    titles = playlist.song_titles
    return DEFAULT_DESCRIPTION if titles.empty?

    count = "#{titles.size} #{"song".pluralize(titles.size)}"
    shown = titles.first(4)
    more = titles.size > shown.size ? ", and more" : ""
    "#{count}: #{shown.join(", ")}#{more}.".truncate(200)
  end

  def social_description(text)
    strip_tags(text.to_s).squish.truncate(200).presence || DEFAULT_DESCRIPTION
  end
end
