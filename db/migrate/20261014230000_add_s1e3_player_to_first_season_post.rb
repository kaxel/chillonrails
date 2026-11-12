# The Indie Music on Tap season 1 recap post embeds a native <audio> player per
# episode, but episode 3's was never added (its file,
# "Indie Music on Tap - S1/chillfiltr-IndieMusiconTap-S1E3_kbnhjk.mp3", is on
# Cloudinary alongside the others). Insert it right after episode 2's notes, in
# front of the divider image that leads into episode 4, using the same markup
# the other players use.
#
# Guarded so it can never block a deploy: if the post or the anchor point isn't
# found (e.g. a fresh database, or the post was edited), it does nothing.
class AddS1e3PlayerToFirstSeasonPost < ActiveRecord::Migration[8.0]
  SLUG = "the-first-season-of-indie-music-on-tap".freeze
  MARKER = "chillfiltr-IndieMusiconTap-S1E3_kbnhjk".freeze

  # Divider image that sits between episode 2's notes and episode 4's player.
  ANCHOR = /<figure[^>]*>(?:(?!<\/figure>).)*?content3-image\.jpg.*?<\/figure>/m

  PLAYER = <<~HTML.strip.freeze
    <div data-rt-embed-type='true'><div style="margin: auto; text-align: center;">
    <span class="w-3/4">
    <audio class="js-player" controls controlsList="nodownload"
      src="https://res.cloudinary.com/ashland-io-llc/video/upload/Indie%20Music%20on%20Tap%20-%20S1/chillfiltr-IndieMusiconTap-S1E3_kbnhjk.mp3">
    </audio>
    </span>
    </div></div><p id="">Episode 3.</p>
  HTML

  class MigrationPost < ActiveRecord::Base
    self.table_name = "posts"
  end

  def up
    post = MigrationPost.find_by(slug: SLUG)
    return say("post #{SLUG} not found; skipping") unless post

    content = post.content.to_s
    return say("episode 3 player already present; skipping") if content.include?(MARKER)

    match = content.match(ANCHOR)
    return say("anchor image not found; skipping") unless match

    post.update!(content: content.insert(match.begin(0), PLAYER))
    say "inserted episode 3 player into #{SLUG}"
  end

  def down
    post = MigrationPost.find_by(slug: SLUG)
    return unless post && post.content.to_s.include?(PLAYER)

    post.update!(content: post.content.sub(PLAYER, ""))
  end
end
