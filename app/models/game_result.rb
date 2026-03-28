class GameResult < ApplicationRecord
  HOUSE_LABELS = {
    "stark" => "Старк",
    "lannister" => "Ланнистер",
    "baratheon" => "Баратеон",
    "greyjoy" => "Грейджой",
    "tyrell" => "Тирелл",
    "martell" => "Мартелл",
    "arryn" => "Аррен",
    "targaryen" => "Таргариен"
  }.freeze

  HOUSE_OPTIONS = HOUSE_LABELS.map { |key, label| [ label, key ] }.freeze
  PLACE_POINTS = { 1 => 15, 2 => 12, 3 => 10, 4 => 8, 5 => 6, 6 => 4, 7 => 2, 8 => 1 }.freeze

  belongs_to :game
  belongs_to :player

  validates :place, numericality: { in: 1..8, only_integer: true }, allow_nil: true
  validates :points, numericality: { only_integer: true }, allow_nil: true
  validates :capitals, :dragons, :castles,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :house, inclusion: { in: HOUSE_LABELS.keys }, allow_nil: true
  validates :player_id, uniqueness: { scope: :game_id }

  def self.house_options
    HOUSE_OPTIONS
  end

  def suggested_points
    return 0 unless place

    base = PLACE_POINTS.fetch(place, 0)
    base + ((capitals || 0) * 2) + (dragons || 0) + (castles || 0)
  end

  def house_name
    HOUSE_LABELS[house]
  end
end
