class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user

  rescue_from ActionController::RoutingError, with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def current_user
    Current.session&.user
  end

  private

  def render_not_found
    # Store the original requested path in session for the 404 page
    session[:not_found_path] = request.original_url
    redirect_to "/404"
  end
end
