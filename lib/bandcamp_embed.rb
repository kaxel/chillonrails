require "net/http"

# Turns a Bandcamp track/album page URL into the URL of Bandcamp's embedded
# player. The page URL doesn't contain the numeric ID the player needs, so we
# fetch the page once and read it from its `bc-page-properties` meta tag.
module BandcampEmbed
  PLAYER_PREFIX = "https://bandcamp.com/EmbeddedPlayer/".freeze
  PLAYER_OPTIONS = "size=large/bgcol=ffffff/linkcol=0687f5/tracklist=false/artwork=small/transparent=true/".freeze
  ITEM_TYPES = { "t" => "track", "a" => "album" }.freeze

  module_function

  # Bandcamp pages live at artist.bandcamp.com, or at an artist's custom
  # domain — which still uses Bandcamp's /track/… and /album/… paths.
  def candidate?(url)
    uri = URI.parse(url.to_s.strip)
    return false unless uri.is_a?(URI::HTTP)
    return true if player_url?(url)

    return false if uri.path.to_s.match?(/\.(mp3|m4a|aac|wav|ogg|oga|flac)\z/i)

    uri.host.to_s.end_with?(".bandcamp.com") || uri.path.to_s.match?(%r{\A/(track|album)/[^/]+/?\z})
  rescue URI::InvalidURIError
    false
  end

  def player_url?(url)
    url.to_s.strip.start_with?(PLAYER_PREFIX)
  end

  # Returns the embedded player URL, or nil if the page isn't a Bandcamp
  # track/album (or couldn't be fetched).
  def player_url_for(url)
    url = url.to_s.strip
    return url if player_url?(url)

    html = fetch(url)
    return unless html

    meta = Nokogiri::HTML5(html).at_css('meta[name="bc-page-properties"]')
    props = JSON.parse(meta&.[]("content") || "{}")
    type = ITEM_TYPES[props["item_type"]]
    return unless type && props["item_id"].present?

    "#{PLAYER_PREFIX}#{type}=#{props['item_id'].to_i}/#{PLAYER_OPTIONS}"
  rescue JSON::ParserError
    nil
  end

  def fetch(url, redirects_left: 3)
    uri = URI.parse(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
      http.get(uri.request_uri, "User-Agent" => "Mozilla/5.0 (compatible; chillfiltr.com)")
    end

    case response
    when Net::HTTPSuccess then response.body
    when Net::HTTPRedirection
      fetch(URI.join(url, response["location"]).to_s, redirects_left: redirects_left - 1) if redirects_left.positive?
    end
  rescue StandardError => e
    Rails.logger.warn("BandcampEmbed: couldn't fetch #{url}: #{e.class}: #{e.message}")
    nil
  end
end
