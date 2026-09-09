class SubmissionSong < ApplicationRecord
  belongs_to :submission

  has_one_attached :audio

  validates :title, presence: true
  validate :audio_attached

  private

  def audio_attached
    errors.add(:audio, "must be uploaded") unless audio.attached?
  end
end
