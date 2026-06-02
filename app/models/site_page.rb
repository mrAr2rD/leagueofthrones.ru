class SitePage < ApplicationRecord
  belongs_to :city

  validates :slug, presence: true, uniqueness: { scope: :city_id }
  validates :title, presence: true
end
