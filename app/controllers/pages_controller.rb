class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :about, :authentification, :radio, :submit ]
  before_action :resume_session, only: [ :authentification ]
  def about
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
