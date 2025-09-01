class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create, :confirm ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_confirmation_instructions
      redirect_to root_url, notice: t("registrations.check_email_confirmation")
    else
      render :new
    end
  end

  def confirm
    @user = User.find_by(confirmation_token: params[:token])

    if @user
      @user.confirm!
      redirect_to root_path, notice: t("registrations.account_confirmed")
    else
      redirect_to root_path, alert: t("registrations.invalid_confirmation_token")
    end
  end

  private

  def user_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end
end
