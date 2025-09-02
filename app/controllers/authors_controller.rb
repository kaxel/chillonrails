class AuthorsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_author, only: [ :show ]

  def index
    @authors = Author.order(:name)
    @page_title = "Authors"
  end

  def show
    @posts = Post.where(author: @author.slug).order(created_at: :desc)
    @page_title = "Author"
  end

  private

  def set_author
    @author = Author.find_by(slug: params[:slug])
    raise ActionController::RoutingError.new("Author (#{params[:slug]}) Not Found") unless @author
  end
end
