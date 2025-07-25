class ErrorsController < ApplicationController
  allow_unauthenticated_access
  def not_found
    @original_path = session.delete(:not_found_path)
  end

  def internal_server_error
  end
end
