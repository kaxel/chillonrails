class User < ApplicationRecord
  has_secure_password validations: false
  has_secure_token :confirmation_token
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :password_required_for_email_users

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end

  def confirmed?
    confirmed_at.present?
  end

  def send_confirmation_instructions
    regenerate_confirmation_token
    UserMailer.confirmation_instructions(self).deliver_now
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  def self.from_omniauth(auth)
    # First try to find by provider + uid
    oauth_user = find_by(provider: auth.provider, uid: auth.uid)
    return oauth_user if oauth_user

    # Check if email already exists (auto-link accounts)
    existing_user = find_by(email_address: auth.info.email)
    if existing_user
      # Link OAuth to existing account
      existing_user.update(
        provider: auth.provider,
        uid: auth.uid,
        confirmed_at: existing_user.confirmed_at || Time.current
      )
      return existing_user
    end

    # Create new OAuth user
    create!(
      email_address: auth.info.email,
      provider: auth.provider,
      uid: auth.uid,
      confirmed_at: Time.current
    )
  end

  private

  def password_required_for_email_users
    return if provider.present? && uid.present?
    return if password_digest.present?
    errors.add(:password, "can't be blank") if password.blank?
  end
end
