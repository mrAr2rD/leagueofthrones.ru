class SitePage < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  validates :title, presence: true

  def self.find_by_slug!(slug)
    find_by!(slug: slug)
  end
end
