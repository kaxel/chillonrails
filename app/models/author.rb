class Author < ApplicationRecord
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :item_id, uniqueness: true, allow_blank: true

  scope :published, -> { where(draft: false) }
  scope :editorial_chiefs, -> { where(editorial_chief: true) }
  scope :by_location, ->(location) { where(location: location) }

  def display_name
    name
  end

  def social_links
    [ social_profile_link_1, social_profile_link_2, social_profile_link_3 ].compact_blank
  end

  def locations_from_hash
    result_array = []
    temp = ""
    self.location.split(";").each do |t|
      temp = t.titleize
      if temp == "Usa" then temp = "USA" end
      if temp == "Uk" then temp = "UK" end
      result_array << temp
    end

    result_array
  end
end
