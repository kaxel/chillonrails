# app/services/example_service.rb
class PostIngest
  def initialize(name)
    @name = name
  end

  def greeting
    "Hello, #{@name}!"
  end
end