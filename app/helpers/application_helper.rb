module ApplicationHelper
  LIGHT_COLOR_BG = [ "bg-slate-50", "bg-slate-100", "bg-slate-200", "bg-gray-50",
      "bg-gray-100", "bg-gray-200", "bg-gray-300", "bg-gray-400", "bg-zinc-50", "bg-zinc-100", "bg-zinc-200", "bg-zinc-300",
      "bg-zinc-400", "bg-zinc-500", "bg-zinc-600", "bg-neutral-50", "bg-neutral-100", "bg-stone-50", "bg-stone-100", "bg-stone-200", "bg-stone-300", "bg-stone-400", "bg-red-50", "bg-red-100",
      "bg-red-200", "bg-red-300", "bg-red-400", "bg-orange-50", "bg-orange-100", "bg-orange-200", "bg-orange-300", "bg-orange-400",
      "bg-orange-500", "bg-amber-50", "bg-amber-100", "bg-amber-200", "bg-amber-300", "bg-amber-400", "bg-amber-500", "bg-yellow-50", "bg-yellow-100", "bg-yellow-200",
      "bg-yellow-300", "bg-yellow-400", "bg-yellow-500", "bg-yellow-600", "bg-lime-50", "bg-lime-100",
      "bg-lime-200", "bg-lime-300", "bg-lime-400", "bg-lime-500", "bg-lime-600", "bg-green-50", "bg-green-100", "bg-green-200", "bg-green-300", "bg-green-400",
      "bg-green-500", "bg-emerald-50", "bg-emerald-100", "bg-emerald-200", "bg-emerald-300", "bg-emerald-400", "bg-emerald-500",
      "bg-teal-50", "bg-teal-100", "bg-teal-200", "bg-teal-300", "bg-teal-400", "bg-cyan-50", "bg-cyan-100", "bg-cyan-200",
      "bg-cyan-300", "bg-sky-50", "bg-sky-100", "bg-sky-200", "bg-sky-300", "bg-sky-400", "bg-sky-500", "bg-sky-600",
      "bg-blue-50", "bg-blue-100", "bg-blue-200", "bg-blue-300", "bg-blue-400", "bg-blue-500", "bg-indigo-50", "bg-indigo-100", "bg-indigo-200",
      "bg-indigo-300", "bg-indigo-400", "bg-indigo-500", "bg-indigo-600", "bg-violet-50", "bg-violet-100", "bg-violet-200", "bg-violet-300", "bg-violet-400",
      "bg-violet-500", "bg-purple-50", "bg-purple-100", "bg-purple-200", "bg-purple-300", "bg-purple-400", "bg-purple-500", "bg-fuchsia-50", "bg-fuchsia-100", "bg-fuchsia-200",
      "bg-fuchsia-300", "bg-fuchsia-400", "bg-fuchsia-500", "bg-fuchsia-600", "bg-pink-50", "bg-pink-100",
      "bg-pink-200", "bg-pink-300", "bg-pink-400", "bg-pink-500", "bg-pink-600", "bg-rose-50", "bg-rose-100", "bg-rose-200", "bg-rose-300", "bg-rose-400",
      "bg-rose-500", "bg-rose-600" ]

  def get_val_string(s)
    # Strip value string from YouTube link code
    # sample input: https://www.youtube.com/watch?v=tAMNPeo7AG0
    # or: https://youtu.be/sVCX9f-fhMc
    # return s
    # puts "running get_val_string for #{s}"
    if s.include?("tu.be")
      new_val = s.split("/").last
    elsif s.include?("watch?")
      new_val = s.split("watch?v=").last
    elsif s.include?("vimeo")
      new_val = s.split("/").last
    else
      # no match
      newval = s
    end

    new_val
  end

  def shorten(s)
    if s.size>60
      "#{s[0, 60]}..."
    else
      s
    end
  end

  def author_photo(author)
    Rails.logger.debug { "#{author} running" }
    if author == "krister-axel"
      "https://res.cloudinary.com/ashland-io-llc/image/upload/c_pad,w_100,h_100,ar_1:1/v1611606713/hytale/krister-axel-thumb_k4qf7c.png"
    else
      "https://res.cloudinary.com/ashland-io-llc/image/upload/t_author-blurb/v1751488873/new-logo--chillfiltr--square-900-clear_p77h4p.png"
    end
  end

  def pretty_author(author)
    s = ""
    # puts "run pretty author for #{author}"
    if author.include?("-")
      parts = author.split("-")
      parts.each do |p|
        s += "#{p.capitalize} "
      end
      s
    else
      author.capitalize
    end
  end

  def get_topic_color(topic)
    case topic
    when "music" then "bg-cyan-600"
    when "lifestyle" then "bg-red-600"
    when "personal" then "bg-gray-600"
    when "technology" then "bg-amber-600"
    when "prose" then "bg-orange-600"
    when "poetry" then "bg-pink-600"
    end
  end

  def get_location_color
    LIGHT_COLOR_BG.sample
  end

  def get_tag_color
    LIGHT_COLOR_BG.sample
  end

  def random_search_message
    [ "A good search is a wonderful thing.", "Good luck with that.", "Gimme some search, said the web user.", "Your answer, just a click away.", "The AI will see you now.",
      "I love the smell of a search in the morning.", "Come on over and search me sometime.", "When the lights go down, in the city...", "I hope you find what you're searching for." ].sample
  end
end
