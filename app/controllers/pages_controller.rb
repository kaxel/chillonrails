class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :about, :authentification, :radio, :submit, :search, :contact, :webflow_migration, :song_promo, :licensing, :cookies, :privacy ]
  before_action :resume_session, only: [ :authentification ]
  
  def about
  end
  
  def search
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
  end

  def radio
  end

  def authentification
  end

  def account
  end
  
  def submit
  end
  
  def webflow_migration
  end
  
  def song_promo
  end
  
  def licensing
  end
  
  def cookies
  end
  
  def privacy
  end
end
