class PostsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]

  def index
    @posts = Post.all(:limit=>"10", id: :desc)
    @posts = @posts.by_topic(params[:topic]).(id: :desc) if params[:topic].present?
  end

  def show
    set_post
        respond_to do |format|
          puts format
          format.html # renders app/views/posts/show.html.erb
          format.json { render json: @post.to_json } # Renders JSON for the post
        end
  end

  def new
    @post = Post.new
  end
  
  def random
    random_post = Post.all.sample
    puts "redirect to: #{random_post.title}"
    redirect_to post_path(random_post.slug), notice: "could be anything"
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      redirect_to @post, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_url, notice: "Post was successfully deleted."
  end

  private

  def set_post
    @post = Post.find_by_slug(params[:slug])
  end

  def post_params
    params.require(:post).permit(:title, :slug, :content, :image, :video_link, :audio_link, :preview, :topic, :location_id, :tag_id)
  end
end
