# Shortens the browser cache for files in public/ that keep their name when they
# change (llms.txt, robots.txt, .well-known/, logos and images).
#
# ActionDispatch::Static gives every file it serves the same far-future
# cache-control (config.public_file_server.headers), which only suits the
# digest-stamped files under /assets/. This sits just in front of it and swaps
# that header for a short one on everything else. Responses from the app itself
# never carry Static's header, so they pass through untouched.
class PublicFileCache
  SHORT = "public, max-age=#{1.hour.to_i}".freeze

  def initialize(app, long:)
    @app = app
    @long = long
  end

  def call(env)
    status, headers, body = @app.call(env)
    if headers["cache-control"] == @long && !env["PATH_INFO"].start_with?("/assets/")
      headers["cache-control"] = SHORT
    end
    [ status, headers, body ]
  end
end
