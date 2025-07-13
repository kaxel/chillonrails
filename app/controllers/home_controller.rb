class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @posts = Post.order( published_on: :desc )
  end
end
