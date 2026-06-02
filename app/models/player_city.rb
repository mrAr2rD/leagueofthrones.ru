class PlayerCity < ApplicationRecord
  belongs_to :player
  belongs_to :city

  validates :player_id, uniqueness: { scope: :city_id }
end
