class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @posts = Post.includes(:location, :tag).order( published_on: :desc )
  end
end
