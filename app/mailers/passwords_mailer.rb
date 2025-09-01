class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: t("passwords.reset_subject"), to: user.email_address
  end
end
