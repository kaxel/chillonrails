class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @posts = Post.includes(:location, :tag)
  end
end
