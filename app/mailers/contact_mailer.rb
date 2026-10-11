class ContactMailer < ApplicationMailer
  default from: "CHILLFILTR® <info@chillfiltr.com>"

  RECIPIENT = "info@chillfiltr.com".freeze

  # Stamp the record once the email has really been sent, so a message that was
  # saved but never delivered is easy to find (ContactMessage.undelivered).
  after_deliver { params[:contact_message].update!(delivered_at: Time.current) }

  # ContactMailer.with(contact_message: record).message_received.deliver_later
  def message_received
    @contact_message = params[:contact_message]

    reply_to = Mail::Address.new(@contact_message.email)
    reply_to.display_name = @contact_message.name

    mail(
      to: RECIPIENT,
      reply_to: reply_to.to_s,
      subject: t("contact.mail_subject", name: @contact_message.name.to_s.squish.truncate(80))
    )
  end
end
