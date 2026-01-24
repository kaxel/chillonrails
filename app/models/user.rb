class User < ApplicationRecord
  has_secure_password validations: false
  has_secure_token :confirmation_token
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :password_required_for_email_users
  validate :admin_email_restriction

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

  def profile_image_url(size: 96)
    return nil if profile_image.blank?

    # For Google OAuth images, append size parameter
    if provider == "google_oauth2" && profile_image.include?("googleusercontent.com")
      "#{profile_image}=s#{size}-c"
    else
      profile_image
    end
  end

  def self.from_omniauth(auth)
    # First try to find by provider + uid
    oauth_user = find_by(provider: auth.provider, uid: auth.uid)
    if oauth_user
      # Update profile image in case it changed
      oauth_user.update(profile_image: auth.info.image) if auth.info.image.present?
      return oauth_user
    end

    # Check if email already exists (auto-link accounts)
    existing_user = find_by(email_address: auth.info.email)
    if existing_user
      # Link OAuth to existing account
      existing_user.update(
        provider: auth.provider,
        uid: auth.uid,
        profile_image: auth.info.image,
        confirmed_at: existing_user.confirmed_at || Time.current
      )
      return existing_user
    end

    # Create new OAuth user
    create!(
      email_address: auth.info.email,
      provider: auth.provider,
      uid: auth.uid,
      profile_image: auth.info.image,
      confirmed_at: Time.current
    )
  end

  private

  def password_required_for_email_users
    return if provider.present? && uid.present?
    return if password_digest.present?
    errors.add(:password, "can't be blank") if password.blank?
  end

  def admin_email_restriction
    return unless admin_changed? && admin?
    return if email_address == "songlistrnet@gmail.com"
    errors.add(:admin, "can only be granted to the authorized account")
  end
end
