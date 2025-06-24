class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create, :confirm]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_confirmation_instructions
      redirect_to root_url, notice: "Please check your email to confirm your account."
    else
      render :new
    end
  end

  def confirm
    @user = User.find_by(confirmation_token: params[:token])

    if @user
      @user.confirm!
      redirect_to root_path, notice: "Your account has been confirmed. Welcome!"
    else
      redirect_to root_path, alert: "Invalid confirmation token."
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
