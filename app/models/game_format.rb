# Реестр игровых форматов — единый источник правды по подсчёту очков,
# который потребляют и Ruby (GameResult), и JS (points_calculator_controller).
#
# Правило подсчёта замков хранится КАК ДАННЫЕ (castle_rule), а не как код,
# чтобы фронт повторял логику один-в-один. См. #to_config_json — это контракт
# с points_calculator_controller.js.
class GameFormat
  DEFAULT_KEY = "mother_of_dragons".freeze

  # Полный набор домов (суперсет). Конкретный формат берёт из него подмножество.
  ALL_HOUSE_LABELS = {
    "stark"     => "Старк",
    "lannister" => "Ланнистер",
    "baratheon" => "Баратеон",
    "greyjoy"   => "Грейджой",
    "tyrell"    => "Тирелл",
    "martell"   => "Мартелл",
    "arryn"     => "Аррен",
    "targaryen" => "Таргариен"
  }.freeze

  attr_reader :key, :label, :players_per_table, :tour_default_count,
              :houses, :place_points, :table_a_bonus_places, :castle_rule,
              :capital_cap

  def initialize(key:, label:, players_per_table:, tour_default_count:, house_keys:,
                 place_points:, table_a_bonus_places:, castle_rule:, capital_cap: 3)
    @key = key.to_s
    @label = label
    @players_per_table = players_per_table
    @tour_default_count = tour_default_count
    @houses = house_keys.to_h { |house_key| [ house_key, ALL_HOUSE_LABELS.fetch(house_key) ] }.freeze
    @place_points = place_points.freeze
    @table_a_bonus_places = table_a_bonus_places.freeze
    @castle_rule = castle_rule.freeze
    @capital_cap = capital_cap
    freeze
  end

  FORMATS = {
    "mother_of_dragons" => new(
      key: "mother_of_dragons",
      label: "Мать драконов (8 игроков)",
      players_per_table: 8,
      tour_default_count: 8,
      house_keys: %w[stark lannister baratheon greyjoy tyrell martell arryn targaryen],
      place_points: { 1 => 12, 2 => 7, 3 => 6, 4 => 5, 5 => 4, 6 => 3, 7 => 2, 8 => 1 },
      table_a_bonus_places: [ 1, 2, 3 ],
      castle_rule: { type: "linear_cap", cap: 5 },
      capital_cap: 3
    ),
    "classic" => new(
      key: "classic",
      label: "Классика (6 игроков)",
      players_per_table: 6,
      tour_default_count: 6,
      house_keys: %w[stark lannister baratheon greyjoy tyrell martell],
      place_points: { 1 => 12, 2 => 8, 3 => 6, 4 => 4, 5 => 2, 6 => 1 },
      table_a_bonus_places: [ 1, 2 ],
      # Замки по диапазонам [min, max, очки]; max == nil — открытый верх.
      castle_rule: { type: "band", table: [ [ 0, 1, 0 ], [ 2, 3, 1 ], [ 4, 5, 2 ], [ 6, 6, 3 ], [ 7, nil, 4 ] ] },
      capital_cap: 3
    )
  }.freeze

  def self.find(key)
    FORMATS.fetch(key.to_s, FORMATS.fetch(DEFAULT_KEY))
  end

  def self.default
    FORMATS.fetch(DEFAULT_KEY)
  end

  def self.all
    FORMATS.values
  end

  def self.keys
    FORMATS.keys
  end

  # Для <select> в админке: [["Мать драконов (8 игроков)", "mother_of_dragons"], ...]
  def self.options
    all.map { |format| [ format.label, format.key ] }
  end

  def place_range
    1..players_per_table
  end

  def league_tier_size
    players_per_table
  end

  def house_keys
    houses.keys
  end

  def house_options
    houses.map { |house_key, label| [ label, house_key ] }
  end

  def place_points_for(place)
    place_points.fetch(place.to_i, 0)
  end

  def table_a_bonus?(place)
    table_a_bonus_places.include?(place.to_i)
  end

  def castle_points(castles)
    count = castles.to_i
    case castle_rule[:type]
    when "linear_cap"
      [ count, castle_rule[:cap] ].min
    when "band"
      row = castle_rule[:table].find { |min, max, _points| count >= min && (max.nil? || count <= max) }
      row ? row[2] : 0
    else
      0
    end
  end

  # Контракт для Stimulus-контроллера points_calculator. Ключи — camelCase,
  # как ожидает JS. nil в band-таблице → null (открытый верх).
  def to_config_json
    {
      placePoints: place_points,
      tableABonusPlaces: table_a_bonus_places,
      capitalCap: capital_cap,
      castleRule: castle_rule
    }.to_json
  end
end
