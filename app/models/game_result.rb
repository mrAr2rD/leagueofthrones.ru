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
  validates :house,
            presence: { message: "должен быть выбран для занятого слота" },
            if: :player_id?
  validates :house,
            inclusion: { in: HOUSE_LABELS.keys, message: "выбран некорректно" },
            allow_blank: true
  validates :house,
            uniqueness: { scope: :game_id, message: "уже выбран за этим столом" },
            allow_blank: true
  validates :house,
            uniqueness: { scope: :player_id, message: "уже использовался этим игроком" },
            allow_blank: true
  validates :player_id, uniqueness: { scope: :game_id }

  def self.house_options
    HOUSE_OPTIONS
  end

  def self.house_options_for(used_houses: [])
    used_houses = Array(used_houses)
    HOUSE_OPTIONS.reject { |(_label, key)| used_houses.include?(key) }
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
