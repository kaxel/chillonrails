class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :about, :authentication, :radio, :search, :contact, :thanks, :licensing, :cookie_policy, :privacy, :terms, :archive ]

  def about
    @page_title = "about"
  end

  def search
    @page_title = "search"
    if params[:search].present?
      @search_term = params[:search]
      Rails.logger.debug { "search for #{@search_term}" }
      @posts = Post.where("lower(title) ILIKE ? OR lower(preview) ILIKE ?", "%#{@search_term.downcase}%", "%#{@search_term.downcase}%")
      Rails.logger.debug { "found #{@posts ? @posts.size : 0} records" }
      if @posts.size == 0
        Rails.logger.debug { "no posts found; search authors" }
        @authors = Author.where("lower(name) ILIKE ?", "%#{@search_term.downcase}%")
        Rails.logger.debug { "author found: #{@authors.first.name}" } unless !@authors.first
        @posts = Post.where(author: @authors.first.slug) unless !@authors.first
        Rails.logger.debug { "found #{@posts ? @posts.size : 0} author matches" } unless !@posts.first
      end
    else
      @posts = nil
    end
  end

  def contact
    @page_title = "contact"
  end

  def thanks
    @page_title = "thanks"
  end

  def radio
    @page_title = "radio"
    radio_posts = Post.by_topic("radio").order(published_on: :desc)
    @latest_episode = radio_posts.first
    older_episodes = @latest_episode ? radio_posts.where.not(id: @latest_episode.id) : radio_posts

    per_page = 4
    max_total = 16

    total_count = [ older_episodes.count, max_total ].min
    @episodes_total_pages = [ (total_count / per_page.to_f).ceil, 1 ].max
    @episodes_page = params[:page].to_i
    @episodes_page = 1 if @episodes_page < 1
    @episodes_page = @episodes_total_pages if @episodes_page > @episodes_total_pages

    offset = (@episodes_page - 1) * per_page
    @episodes = older_episodes.offset(offset).limit(per_page)
  end

  def authentication
    @page_title = "authentication"
  end

  def account
    @page_title = "account"
  end

  def licensing
    @page_title = "licensing"
  end

  def cookie_policy
    @page_title = "cookies"
  end

  def privacy
    @page_title = "privacy"
  end

  def archive
    @page_title = "archive"
    @posts_by_month = Post.where.not(published_on: nil)
                          .order(published_on: :desc)
                          .group_by { |post| post.published_on.strftime("%Y-%m") }
  end
end
