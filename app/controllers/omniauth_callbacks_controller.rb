class OmniauthCallbacksController < ApplicationController
  allow_unauthenticated_access

  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: t("authentication.signed_in_with_google")
    else
      redirect_to new_session_path, alert: t("authentication.authentication_failed")
    end
  end

  def apple
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: t("authentication.signed_in_with_apple")
    else
      redirect_to new_session_path, alert: t("authentication.authentication_failed")
    end
  end

  def failure
    redirect_to new_session_path, alert: t("authentication.authentication_failed")
  end
end
