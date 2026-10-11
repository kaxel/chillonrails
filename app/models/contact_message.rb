# A message from the public contact form. It is saved, then emailed to the
# site inbox (see ContactMailer); delivered_at records when that email went out.
#
# Two kinds of spam handling, from certain to uncertain:
# - #spam? messages (filled honeypot, or submitted too fast / without a valid
#   form token) are bots. The controller drops them without saving.
# - suspected_spam messages (lots of links) might be real, so they are saved and
#   emailed, just labelled.
class ContactMessage < ApplicationRecord
  # People take longer than this to write a message; scripts don't.
  MIN_FILL_SECONDS = 3
  # How long a rendered form stays submittable.
  FORM_TOKEN_LIFETIME = 30.days
  # Messages with this many links or more are labelled as suspected spam.
  LINK_LIMIT = 3
  LINK_PATTERN = %r{(?:https?://|www\.)\S+}i

  # Virtual, never saved. Honeypot: hidden from people, filled in by bots.
  attribute :website, :string
  # Virtual, never saved. Signed timestamp of when the form was shown.
  attribute :form_token, :string

  validates :name, :email, :message, presence: true
  validates :name, length: { maximum: 200 }
  validates :email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :message, length: { maximum: 5000 }
  # These end up in email headers, so never allow line breaks in them.
  validates :name, :email, format: { without: /[\r\n]/, message: :invalid }

  before_create { self.suspected_spam = suspicious_links? }

  scope :undelivered, -> { where(delivered_at: nil) }

  # A signed "the form was shown at this moment" token for the hidden field.
  def self.new_form_token
    form_token_verifier.generate(Time.current.to_i, purpose: :contact_form, expires_in: FORM_TOKEN_LIFETIME)
  end

  def self.form_token_verifier
    Rails.application.message_verifier(:contact_form)
  end

  def spam?
    spam_reason.present?
  end

  # Why this looks like a bot, or nil. Used for the log line when one is dropped.
  def spam_reason
    if website.present?
      :honeypot
    elsif submitted_too_fast?
      :too_fast
    end
  end

  def suspicious_links?
    "#{name} #{message}".scan(LINK_PATTERN).size >= LINK_LIMIT
  end

  private

  # A missing, forged, or expired token counts too: a bot posting straight to
  # the endpoint never loaded the form, so it has no valid token.
  def submitted_too_fast?
    shown_at = self.class.form_token_verifier.verified(form_token, purpose: :contact_form)
    shown_at.nil? || Time.current.to_i - shown_at < MIN_FILL_SECONDS
  end
end
