module ApplicationHelper
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
    when "music" then "bg-moss"
    when "lifestyle" then "bg-clay"
    when "personal" then "bg-sky"
    when "technology" then "bg-stone"
    when "prose" then "bg-sienna"
    when "poetry" then "bg-heather"
    end
  end

  def random_search_message
    [ "A good search is a wonderful thing.", "Good luck with that.", "Gimme some search, said the web user.", "Your answer, just a click away.", "The AI will see you now.",
      "I love the smell of a search in the morning.", "Come on over and search me sometime.", "When the lights go down, in the city...", "I hope you find what you're searching for." ].sample
  end
end
