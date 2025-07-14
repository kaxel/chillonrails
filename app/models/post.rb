class Post < ApplicationRecord
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :content, presence: true
  
  validates :video_link, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }, allow_blank: true
  validates :audio_link, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }, allow_blank: true

  before_validation :generate_slug
  before_validation :generate_preview

  scope :by_topic, ->(topic) { where(topic: topic) }
  
  def locations_from_hash
    result_array = []
    temp = ""
    self.location.split(";").each do |t|
      temp = t.titleize
      if temp == "Usa" then temp = "USA" end
      if temp == "Uk" then temp = "UK" end
    end
    result_array << temp
    return result_array
  end
  
  def tags_from_hash
    self.tags.split(";").map {|t| t.titleize }
  end
  
  private

  def generate_slug
    self.slug = title.parameterize if title.present? && slug.blank?
  end

  def generate_preview
    self.preview = content.truncate(200) if content.present? && preview.blank?
  end
  
end
