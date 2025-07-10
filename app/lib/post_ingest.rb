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
end