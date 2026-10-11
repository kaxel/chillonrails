# Base for admin-only pages. Signing in is enforced by the Authentication concern
# (it runs first); this adds the admin check on top.
module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      redirect_to root_path, alert: t("authorization.admin_required") unless Current.user&.admin?
    end
  end
end
