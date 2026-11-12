namespace :substack do
  # Both tasks take a post slug and default to the most recently published post.
  find_post = lambda do |slug|
    post = slug.present? ? Post.find_by(slug: slug) : Post.order(published_on: :desc, id: :desc).first
    abort "No post found for slug #{slug.inspect}" unless post
    puts "Post: #{post.title} (#{post.slug})"
    post
  end

  export = lambda do |post|
    html = Substack::PostDraft.new(post).to_html
    path = Rails.root.join("tmp/substack/#{post.slug}.html")
    FileUtils.mkdir_p(path.dirname)
    File.write(path, html)
    puts "Wrote #{path}"

    # Put it on the clipboard as rich HTML so it pastes formatted into the editor.
    if system("osascript", "-e", "set the clipboard to «data HTML#{html.unpack1('H*')}»", out: File::NULL)
      puts "Copied to clipboard — paste into the Substack editor (title: #{post.title.inspect})"
    end
    if (pub = ENV["SUBSTACK_PUBLICATION_URL"]).present?
      system("open", "#{pub.chomp('/')}/publish/post?type=newsletter")
    end
  end

  desc "Create a Substack draft from a post via Substack's private API (falls back to export). Usage: bin/rails 'substack:draft[slug]'; DRY_RUN=1 prints the payload"
  task :draft, [ :slug ] => :environment do |_t, args|
    post = find_post.call(args[:slug])

    if ENV["DRY_RUN"].present?
      draft = Substack::PostDraft.new(post)
      puts JSON.pretty_generate(title: draft.title, subtitle: draft.subtitle, body: draft.body)
      next
    end

    begin
      client = Substack::Client.from_env
      draft = Substack::PostDraft.new(post, image_resolver: client.method(:upload_image))
      url = client.create_draft(draft)
      puts "Draft created: #{url}"
      system("open", url)
    rescue Substack::Client::Error => e
      warn "Substack API failed: #{e.message}"
      warn "Falling back to export…"
      export.call(post)
    end
  end

  desc "Export a post as Substack-ready HTML, copy it to the clipboard and open the editor. Usage: bin/rails 'substack:export[slug]'"
  task :export, [ :slug ] => :environment do |_t, args|
    export.call(find_post.call(args[:slug]))
  end
end
