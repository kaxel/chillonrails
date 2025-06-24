class PagesController < ApplicationController
  allow_unauthenticated_access only: [:about,:authentification]
  before_action :resume_session, only: [:authentification]
  def about
  end

  def authentification
  end

  def account
  end
end
