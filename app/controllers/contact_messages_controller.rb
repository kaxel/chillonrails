class ContactMessagesController < ApplicationController
  allow_unauthenticated_access only: :create

  # The form is public and sends email, so cap it per IP.
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to pages_contact_path, alert: t("contact.rate_limited") }

  def create
    @contact_message = ContactMessage.new(contact_params)

    # Bots fill the hidden honeypot field. Act as if it worked so they learn nothing.
    return redirect_to(pages_thanks_path) if @contact_message.spam?

    if @contact_message.save
      ContactMailer.with(contact_message: @contact_message).message_received.deliver_later
      redirect_to pages_thanks_path
    else
      @page_title = "contact"
      render "pages/contact", status: :unprocessable_content
    end
  end

  private

  def contact_params
    params.fetch(:contact_message, {}).permit(:name, :email, :message, :website)
  end
end
