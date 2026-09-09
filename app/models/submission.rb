class Submission < ApplicationRecord
  PRICE_PER_SONG_CENTS = 300

  has_many :submission_songs, dependent: :destroy
  accepts_nested_attributes_for :submission_songs,
    reject_if: ->(attrs) { attrs[:title].blank? && attrs[:audio].blank? }

  has_secure_token :token

  validates :contact_name, :email, :artist_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: %w[pending paid] }
  validate :at_least_one_song

  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }

  def recalculate_amount!
    update!(amount_cents: song_count * PRICE_PER_SONG_CENTS)
  end

  def song_count
    submission_songs.size
  end

  def amount_dollars
    amount_cents / 100.0
  end

  def paid?
    status == "paid"
  end

  def mark_paid!
    update!(status: "paid")
  end

  def to_param
    token
  end

  private

  def at_least_one_song
    errors.add(:base, "Add at least one song with a title and file") if submission_songs.reject(&:marked_for_destruction?).empty?
  end
end
