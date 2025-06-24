class UserMailer < ApplicationMailer
  def confirmation_instructions(user)
    @user = user
    @confirmation_url = confirm_registration_url(token: @user.confirmation_token)

    mail(to: @user.email_address, subject: "Confirm your account")
  end
end
