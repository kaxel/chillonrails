class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :about, :authentication, :radio, :submit, :search, :contact, :webflow_migration, :song_promo, :licensing, :cookies, :privacy, :support, :archive ]
  before_action :resume_session, only: [ :authentication ]

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
        Rails.logger.debug { "author found: #{@authors.first.name}" }
        @posts = Post.where(author: @authors.first.slug)
        Rails.logger.debug { "found #{@posts ? @posts.size : 0} author matches" }
      end
    else
      @posts = nil
    end
  end

  def support
    @page_title = "support the channel"
  end

  def contact
    @page_title = "contact"
  end

  def radio
    @page_title = "radio"
  end

  def authentication
    @page_title = "authentication"
  end

  def account
    @page_title = "account"
  end

  def submit
    @page_title = "submit"
  end

  def webflow_migration
    @page_title = "webflow migration"
  end

  def song_promo
    @page_title = "song promo"
  end

  def licensing
    @page_title = "licensing"
  end

  def cookies
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
