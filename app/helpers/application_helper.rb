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
    else
      # no match
      newval = s
    end
    
    return new_val
  end
  
  def pretty_author(author)
    s = ""
    # puts "run pretty author for #{author}"
    if author.include?("-")
      parts = author.split("-")
      parts.each do |p|
        s += "#{p.capitalize} "
      end
      return s
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
  
end
