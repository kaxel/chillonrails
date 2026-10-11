# A message from the public contact form. It is saved, then emailed to the
# site inbox (see ContactMailer); delivered_at records when that email went out.
class ContactMessage < ApplicationRecord
  # Honeypot: hidden from people, filled in by bots. Never saved.
  attribute :website, :string

  validates :name, :email, :message, presence: true
  validates :name, length: { maximum: 200 }
  validates :email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :message, length: { maximum: 5000 }
  # These end up in email headers, so never allow line breaks in them.
  validates :name, :email, format: { without: /[\r\n]/, message: :invalid }

  scope :undelivered, -> { where(delivered_at: nil) }

  def spam?
    website.present?
  end
end
