class PostsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :random ]

  def index
    @posts = @posts.by_topic(params[:topic]).(id: :desc) if params[:topic].present?
    @posts = Post.all(:limit=>"10", id: :desc) unless @posts
  end

  def show
    @random_link = Post.order(Arel.sql('RANDOM()')).first.slug
    set_post
    @from_home = params[:from_home] == 'true' || request.referer&.include?(root_path)
    @available_topics = Post.where.not(topic: [nil, '']).group(:topic).having('COUNT(*) > 0').distinct.pluck(:topic).sort
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
    #random_post = Post.all.sample
    @post = Post.order(Arel.sql('RANDOM()')).first
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
    raise ActionController::RoutingError.new('Not Found') unless @post
  end

  def post_params
    params.require(:post).permit(:title, :slug, :content, :image, :video_link, :audio_link, :preview, :topic, :location_id, :tag_id)
  end
end
