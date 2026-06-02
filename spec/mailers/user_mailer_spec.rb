require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  # NOTE: UserMailer#confirmation_instructions currently references
  # `confirm_registration_url`, a route that no longer exists in config/routes.rb,
  # so the mailer cannot be rendered/tested until the registration routes are
  # restored or the mailer is removed.
  pending "restore registration routes before testing confirmation_instructions"
end
