class ErrorsController < ApplicationController
  allow_unauthenticated_access
  def not_found
    @original_path = session.delete(:not_found_path)
    
    # Log the 404 error to PageNotFound table
    url_to_log = @original_path.present? ? @original_path : request.original_url
    PageNotFound.create(url: url_to_log, accessed_at: Time.current)
  end

  def internal_server_error
  end
end
