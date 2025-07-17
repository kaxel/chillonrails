# app/services/example_service.rb
class PostIngest  
  def initialize(name)
    @name = name
    @slug = ""
    @title = ""
    @image = ""
    @content = "this is sample content"
  end

  def greeting
    "Hello, #{@name}!"
  end
  
  def feed_line(s_input)
    @slug = s_input[1]
    @created_on = s_input[7].to_date.strftime("%F")
    @image = s_input[11]
    @preview = s_input[12]
    @author = s_input[13]
    @reading_time = s_input[14].to_i
    @topic = s_input[15]
    @location = s_input[21]
    @tags = s_input[20]
    @published_on = s_input[9].to_date.strftime("%F")
    @created_on = s_input[7].to_date.strftime("%F")
    @tags = s_input[20]
    @location = s_input[21]
    @video = s_input[22].nil? ? "" : s_input[22]
    @audio = s_input[23].nil? ? "" : s_input[23]
    @title = s_input[0]
    @content = s_input[10]
  end
  
  def locations_from_hash
    # duplicated in the Post class
    newlist = self.location.split(";")
    newlist_return = self.location.split(";").map {|t| t.titleize }
    newlist_return
  end
  
  def slug
    @slug
  end
  
  def created_on
    @created_on
  end
  
  def image
    @image
  end
  
  def preview
    @preview
  end
  
  def author
    @author
  end
  
  def reading_time
    @reading_time
  end
  
  def topic
    @topic
  end
  
  def published_on
    @published_on
  end
  
  def published_on
    @created_on
  end
  
  def tags
    @tags
  end
  
  def location
    @location
  end
  
  def video
    @video
  end
  
  def audio
    @audio
  end
  
  def title
    @title
  end
  
  def content
    @content
  end
  
  def content_link
    # look for img tag
    x = @content.scan(/<img[^>]*src="([^"]*)"[^>]*>/)
    x.flatten
  end
  
end