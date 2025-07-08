class Post < ApplicationRecord
  belongs_to :location, optional: true
  belongs_to :tag, optional: true
  
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :content, presence: true
  validates :video_link, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }, allow_blank: true
  validates :audio_link, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }, allow_blank: true
  
  before_validation :generate_slug
  before_validation :generate_preview
  
  scope :by_topic, ->(topic) { where(topic: topic) }
  scope :with_location, -> { joins(:location) }
  scope :with_tag, -> { joins(:tag) }
  
  private
  
  def generate_slug
    self.slug = title.parameterize if title.present?
  end
  
  def generate_preview
    self.preview = content.truncate(200) if content.present? && preview.blank?
  end
end