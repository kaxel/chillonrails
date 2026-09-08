namespace :weekly_catch do
  desc "Import Weekly Catch episodes from db/data/weekly_catch_episodes.json as Posts"
  task import: :environment do
    path = Rails.root.join("db/data/weekly_catch_episodes.json")
    unless File.exist?(path)
      abort "No such file: #{path} — run export_weekly_catch_to_chillfiltr.rb first."
    end

    episodes = JSON.parse(File.read(path))
    created = 0
    skipped = 0

    episodes.each do |ep|
      date = Date.parse(ep["date"])
      title = "The Weekly Catch — #{date.strftime('%B %-d, %Y')}"
      slug = title.parameterize

      if Post.exists?(slug: slug)
        skipped += 1
        next
      end

      tracklist_html = ep["tracks"].map do |t|
        "<li><strong>#{ERB::Util.html_escape(t['artist'])}</strong> — #{ERB::Util.html_escape(t['song'])}</li>"
      end.join

      content = <<~HTML
        <p>Live from KSKQ 89.5 FM Ashland, Oregon — Roots-Folk, Indie Rock, and Electronica curated by Krister Axel.</p>
        <ol>#{tracklist_html}</ol>
      HTML

      # Post#preview auto-generates from content.truncate(200) when left
      # blank — but that truncates the raw HTML string itself, and the show
      # page renders preview unescaped, so it'd print literal "<p>" tags.
      # Set a clean plain-text one explicitly instead.
      artists = ep["tracks"].first(5).map { |t| t["artist"] }.join(", ")
      preview = "#{ep['tracks'].size} tracks: #{artists}, and more."

      Post.create!(
        title: title,
        slug: slug,
        content: content,
        preview: preview,
        topic: "radio",
        author: "krister-axel",
        published_on: date,
        location: "Ashland;Oregon",
        tags: "Weekly Catch;KSKQ",
        image: ep.fetch("image_path", "https://weeklycatch.org/art/weekly-catch-small.png"),
        video_link: ep["mixcloud_url"]
      )
      created += 1
    end

    puts "Created #{created} post(s), skipped #{skipped} (already existed)."
  end
end
