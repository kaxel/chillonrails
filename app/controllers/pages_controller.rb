class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :about, :authentification, :radio, :submit, :search, :contact ]
  before_action :resume_session, only: [ :authentification ]
  
  def about
  end
  
  def search
    if params[:search].present?
      @posts = Post.where("title LIKE ?", "%#{params[:search]}%")
    else
      @post = nil
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
end
