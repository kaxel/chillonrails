class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :about, :authentification, :radio, :submit, :search, :contact, :webflow_migration, :song_promo, :licensing, :cookies, :privacy ]
  before_action :resume_session, only: [ :authentification ]
  
  def about
    @page_title = "about"  
  end
  
  def search
    @page_title = "search"  
    if params[:search].present?
      @search_term = params[:search]
      puts "search for #{@search_term}"
      @posts = Post.where("lower(title) ILIKE ? OR lower(preview) ILIKE ?", "%#{@search_term.downcase}%", "%#{@search_term.downcase}%" )
      puts "found #{@posts ? @posts.size : 0} records"
    else
      @posts = nil
    end
  end
  
  def contact
    @page_title = "contact"
  end

  def radio
    @page_title = "radio"
  end

  def authentification
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
end
