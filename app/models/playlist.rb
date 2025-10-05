class Playlist < ApplicationRecord
  validates :name, presence: true

  attribute :songs, :jsonb, default: {}
end
