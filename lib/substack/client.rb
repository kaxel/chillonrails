require "net/http"
require "base64"

module Substack
  # Minimal client for Substack's private web API — the same endpoints the
  # Substack editor calls. There is no official publishing API, so this
  # authenticates with the `substack.sid` cookie from a logged-in browser
  # session and may break if Substack changes things.
  class Client
    class Error < StandardError; end

    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0 Safari/537.36".freeze

    attr_reader :publication_url

    def self.from_env
      new(
        publication_url: ENV.fetch("SUBSTACK_PUBLICATION_URL") { raise Error, "Set SUBSTACK_PUBLICATION_URL in .env (e.g. https://chillfiltr.substack.com)" },
        sid: ENV.fetch("SUBSTACK_SID") { raise Error, "Set SUBSTACK_SID in .env (the substack.sid cookie from your browser)" }
      )
    end

    def initialize(publication_url:, sid:)
      @publication_url = publication_url.chomp("/")
      @sid = sid
    end

    def user_id
      @user_id ||= request(:get, "https://substack.com/api/v1/user/profile/self").fetch("id")
    end

    # Creates an unpublished draft and returns the editor URL for it.
    def create_draft(draft)
      response = request(:post, "#{publication_url}/api/v1/drafts", {
        draft_title: draft.title,
        draft_subtitle: draft.subtitle,
        draft_body: draft.body.to_json,
        draft_bylines: [ { id: user_id, is_guest: false } ],
        audience: "everyone",
        section_chosen: true,
        draft_section_id: nil,
        write_comment_permissions: "everyone"
      })
      "#{publication_url}/publish/post/#{response.fetch('id')}"
    end

    # Re-hosts an image on Substack's CDN so it doesn't hotlink chillfiltr.com.
    # Falls back to the original URL if the download or upload fails.
    def upload_image(url)
      image = Net::HTTP.get_response(URI(url))
      raise Error, "GET #{url} returned #{image.code}" unless image.is_a?(Net::HTTPSuccess)

      data_uri = "data:#{image.content_type};base64,#{Base64.strict_encode64(image.body)}"
      request(:post, "#{publication_url}/api/v1/image", { image: data_uri }).fetch("url")
    rescue StandardError => e
      warn "  Couldn't upload #{url} to Substack (#{e.message}); linking the original."
      url
    end

    private

    def request(method, url, payload = nil)
      uri = URI(url)
      req = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
      req["Cookie"] = "substack.sid=#{@sid}"
      req["User-Agent"] = USER_AGENT
      req["Accept"] = "application/json"
      if payload
        req["Content-Type"] = "application/json"
        req.body = payload.to_json
      end

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 60) { |http| http.request(req) }
      unless response.is_a?(Net::HTTPSuccess)
        hint = response.code.in?(%w[401 403]) ? " — your SUBSTACK_SID cookie has probably expired" : ""
        raise Error, "#{method.upcase} #{uri.path} returned #{response.code}#{hint}: #{response.body.to_s[0, 300]}"
      end
      JSON.parse(response.body)
    rescue JSON::ParserError
      raise Error, "#{method.upcase} #{uri.path} returned non-JSON (Substack may have blocked the request)"
    end
  end
end
