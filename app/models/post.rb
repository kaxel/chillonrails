class Post < ApplicationRecord
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :content, presence: true

  validates :video_link, format: { with: URI::DEFAULT_PARSER.make_regexp, message: I18n.t("posts.must_be_valid_url") }, allow_blank: true
  validates :audio_link, format: { with: URI::DEFAULT_PARSER.make_regexp, message: I18n.t("posts.must_be_valid_url") }, allow_blank: true

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
    result_array
  end

  def tags_from_hash
    Rails.logger.debug self.tags
    if self.tags.downcase.include?("poetry;")
      # it's a hack, but it's easy: because the topic is already poetry, a poetry tag is redundant
      Rails.logger.debug "removed poetry;"
      new_result = self.tags.gsub("poetry;", "")
    elsif self.tags.downcase.include?("poetry")
      new_result = self.tags.gsub("; poetry", "")
      new_result = new_result.gsub("poetry", "")
      Rails.logger.debug "removed poetry"
    else
      new_result = self.tags
    end
    if self.tags.downcase.include?("prose;")
      # it's a hack, but it's easy: because the topic is already prose, a prose tag is redundant
      Rails.logger.debug "removed prose;"
      new_result = self.tags.gsub("prose;", "")
    elsif self.tags.downcase.include?("prose")
      new_result = self.tags.gsub("; prose", "")
      new_result = new_result.gsub("prose", "")
      Rails.logger.debug "removed prose"
    else
      new_result = self.tags
    end
    new_result.split(";").map { |t| t.titleize }
  end

  private

  def generate_slug
    self.slug = title.parameterize if title.present? && slug.blank?
  end

  def generate_preview
    self.preview = content.truncate(200) if content.present? && preview.blank?
  end
end
