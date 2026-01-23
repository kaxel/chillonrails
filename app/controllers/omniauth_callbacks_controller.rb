class OmniauthCallbacksController < ApplicationController
  allow_unauthenticated_access

  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: "Successfully signed in with Google."
    else
      redirect_to new_session_path, alert: "Authentication failed. Please try again."
    end
  end

  def apple
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: "Successfully signed in with Apple."
    else
      redirect_to new_session_path, alert: "Authentication failed. Please try again."
    end
  end

  def failure
    redirect_to new_session_path, alert: "Authentication failed. Please try again."
  end
end
