class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @page = params[:page]&.to_i || 1
    @per_page = 20
    @offset = (@page - 1) * @per_page

    # Get posts with distinct to avoid any potential duplicates
    @posts = if params[:topic].present?
               Post.by_topic(params[:topic]).order(published_on: :desc).offset(@offset).limit(@per_page).distinct
    else
               Post.order(published_on: :desc).offset(@offset).limit(@per_page).distinct
    end

    @top12 = Post.order("score asc").last(4)

    @available_topics = Post.where.not(topic: [ nil, "" ]).group(:topic).having("COUNT(*) > 0").distinct.pluck(:topic).sort
    @current_topic = params[:topic]
    @page_title = @current_topic ? @current_topic : "Welcome."

    respond_to do |format|
      format.html
      format.turbo_stream { render "posts_page", locals: { posts: @posts, page: @page } }
    end
  end

  # Standalone preview of the "Color-Blocked Sections" home page direction,
  # for comparing live against the current design (index). Not linked from
  # navigation — direct URL only. Safe to remove once a direction is picked.
  def color_blocked
    @posts = Post.order(published_on: :desc).limit(6).distinct
    @top12 = Post.order("score asc").last(4)
    @page_title = "Welcome. (Color-Blocked preview)"
  end
end
