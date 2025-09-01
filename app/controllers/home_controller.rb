class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @page = params[:page]&.to_i || 1
    @per_page = 20
    @offset = (@page - 1) * @per_page

    @posts = if params[:topic].present?
               Post.by_topic(params[:topic]).order(published_on: :desc).offset(@offset).limit(@per_page)
    else
               Post.order(published_on: :desc).offset(@offset).limit(@per_page)
    end

    @top12 = Post.order("score asc").last(12)

    @available_topics = Post.where.not(topic: [ nil, "" ]).group(:topic).having("COUNT(*) > 0").distinct.pluck(:topic).sort
    @current_topic = params[:topic]
    @page_title = @current_topic ? @current_topic : "Welcome."
    
    respond_to do |format|
      format.html
      format.turbo_stream { render "posts_page", locals: { posts: @posts, page: @page } }
    end
  end
end
