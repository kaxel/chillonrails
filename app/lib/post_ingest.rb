# app/services/example_service.rb
class PostIngest
  # order of fields: name, slug, created on, image, preview, author, reading time, topic, published on, tags, location, video, audio
  
  def initialize(name)
    @name = name
    @slug = ""
    @title = ""
    @image = ""
  end

  def greeting
    "Hello, #{@name}!"
  end
  
  def feed_line(s_input)
    slices = s_input.split(",")
    @slug = slices[1]
    @created_on = slices[2].to_date.strftime("%F")
    @image = slices[3]
    @preview = slices[4]
    @author = slices[5]
    @reading_time = slices[6].to_i
    @topic = slices[7]
    @published_on = slices[8].to_date.strftime("%F")
    @tags = slices[9]
    @location = slices[10]
    @video = slices[11]
    @audio = slices[12]
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
  
  
end