class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @posts = if params[:topic].present?
               Post.by_topic(params[:topic]).order( published_on: :desc )
             else
               Post.order( published_on: :desc )
             end
             
             
    @top20 = Post.order("score asc").last(20)  
        
    @available_topics = Post.where.not(topic: [nil, '']).group(:topic).having('COUNT(*) > 0').distinct.pluck(:topic).sort
    @current_topic = params[:topic]
    @page_title = @current_topic ? @current_topic : "Welcome."
  end
end
