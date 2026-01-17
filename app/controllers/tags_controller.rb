class TagsController < ApplicationController
  allow_unauthenticated_access

  def index
    @tags = Tag.order(:name)
    @page_title = "All Tags"
  end

  def show
    @tag = Tag.find_by(slug: params[:slug])
    raise ActionController::RoutingError.new("Tag (#{params[:slug]}) Not Found") unless @tag

    @page = params[:page]&.to_i || 1
    @per_page = 20
    @offset = (@page - 1) * @per_page

    # Find posts where the tags field contains this exact tag (case-insensitive)
    # Match tag at start, middle, or end with semicolon delimiters
    # Patterns: "tagname;", "; tagname;", "; tagname", or exact match "tagname"
    @posts = Post.where(
      "tags ILIKE ? OR tags ILIKE ? OR tags ILIKE ? OR tags ILIKE ?",
      "#{@tag.name};%",      # Tag at start: "folktronica; other"
      "%; #{@tag.name};%",   # Tag in middle: "other; folktronica; another"
      "%; #{@tag.name}",     # Tag at end: "other; folktronica"
      @tag.name              # Exact match (only tag): "folktronica"
    ).order(published_on: :desc)
     .offset(@offset)
     .limit(@per_page)
     .distinct

    @available_topics = Post.where.not(topic: [ nil, "" ]).group(:topic).having("COUNT(*) > 0").distinct.pluck(:topic).sort
    @page_title = "Posts tagged with #{@tag.name}"

    respond_to do |format|
      format.html { render "tags/show" }
      format.turbo_stream
    end
  end
end
