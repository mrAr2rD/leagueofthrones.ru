class GameResult < ApplicationRecord
  # Ярлыки домов — суперсет всех форматов (для рендера старых строк).
  HOUSE_LABELS = GameFormat::ALL_HOUSE_LABELS

  HOUSE_OPTIONS = HOUSE_LABELS.map { |key, label| [ label, key ] }.freeze
  # Сохранены для обратной совместимости (тесты/сиды). Реальный подсчёт идёт
  # через формат тура — см. #game_format и self.calculate_points.
  MAX_CAPITAL_POINTS = GameFormat.default.capital_cap
  MAX_CASTLES_POINTS = 5

  belongs_to :game
  belongs_to :player

  validates :place, numericality: { only_integer: true }, allow_nil: true
  validates :points, numericality: { only_integer: true }, allow_nil: true
  validates :capitals, :dragons, :castles,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :capital_captures, :capital_controls, :lands, :skulls,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :house,
            presence: { message: "должен быть выбран для занятого слота" },
            if: :player_id?
  validate :place_within_format_range
  validate :house_allowed_in_format
  validate :player_unique_within_game
  validate :house_unique_within_game
  validate :house_unique_for_player

  def self.house_options(format: GameFormat.default)
    format.house_options
  end

  def self.house_options_for(used_houses: [], format: GameFormat.default)
    used_houses = Array(used_houses)
    format.house_options.reject { |(_label, key)| used_houses.include?(key) }
  end

  def self.effective_capitals(capitals:, capital_captures: nil, capital_controls: nil)
    return capitals.to_i if capital_captures.nil? && capital_controls.nil?

    capital_captures.to_i + capital_controls.to_i
  end

  def self.capital_points(capitals:, capital_captures: nil, capital_controls: nil, format: GameFormat.default)
    [ effective_capitals(
      capitals: capitals,
      capital_captures: capital_captures,
      capital_controls: capital_controls
    ), format.capital_cap ].min
  end

  def self.ranking_captures(capitals:, capital_captures: nil, capital_controls: nil)
    return capitals.to_i if capital_captures.nil? && capital_controls.nil?

    capital_captures.to_i
  end

  def self.calculate_points(place:, capitals: 0, capital_captures: nil, capital_controls: nil, dragons:, castles:, table_letter:, format: GameFormat.default)
    normalized_place = place.to_i
    return nil if normalized_place <= 0

    place_points = format.place_points_for(normalized_place)
    table_bonus = table_letter == "A" && format.table_a_bonus?(normalized_place) ? 1 : 0

    place_points + table_bonus +
      capital_points(
        capitals: capitals,
        capital_captures: capital_captures,
        capital_controls: capital_controls,
        format: format
      ) +
      dragons.to_i +
      format.castle_points(castles)
  end

  def suggested_points
    calculated_points || 0
  end

  def effective_capitals
    self.class.effective_capitals(
      capitals: capitals,
      capital_captures: capital_captures,
      capital_controls: capital_controls
    )
  end

  def capital_bonus_points
    self.class.capital_points(
      capitals: capitals,
      capital_captures: capital_captures,
      capital_controls: capital_controls,
      format: game_format
    )
  end

  # Формат тура, к которому относится этот результат (дефолт — Мать драконов).
  def game_format
    game&.tour&.game_format || GameFormat.default
  end

  def ranking_captures
    self.class.ranking_captures(
      capitals: capitals,
      capital_captures: capital_captures,
      capital_controls: capital_controls
    )
  end

  def using_legacy_capitals?
    capital_captures.nil? && capital_controls.nil?
  end

  def house_name
    HOUSE_LABELS[house]
  end

  private

  def calculated_points
    self.class.calculate_points(
      place: place,
      capitals: capitals,
      capital_captures: capital_captures,
      capital_controls: capital_controls,
      dragons: dragons,
      castles: castles,
      table_letter: game&.table_letter,
      format: game_format
    )
  end

  def place_within_format_range
    return if place.blank?

    range = game_format.place_range
    return if range.cover?(place)

    errors.add(:place, "должно быть от #{range.min} до #{range.max}")
  end

  def house_allowed_in_format
    return if house.blank?
    return if game_format.house_keys.include?(house)

    errors.add(:house, "выбран некорректно")
  end

  def player_unique_within_game
    return unless player_id? && game_id?
    return unless sibling_results.any? { |result| result.player_id == player_id }

    errors.add(:player_id, "уже выбран за этим столом")
  end

  def house_unique_within_game
    return if house.blank? || game_id.blank?
    return unless sibling_results.any? { |result| result.house == house }

    errors.add(:house, "уже выбран за этим столом")
  end

  def house_unique_for_player
    return if house.blank? || player_id.blank?

    duplicate_in_current_game = sibling_results.any? do |result|
      result.player_id == player_id && result.house == house
    end
    duplicate_results = GameResult.where(player_id: player_id, house: house)
                                  .where.not(game_id: game_id)
                                  .where.not(id: id)
    if game&.tour&.allows_house_reuse?
      duplicate_results = duplicate_results.joins(:game).where(games: { tour_id: game.tour_id })
    end
    duplicate_in_other_games = duplicate_results.exists?
    return unless duplicate_in_current_game || duplicate_in_other_games

    errors.add(:house, "уже использовался этим игроком")
  end

  def sibling_results
    return [] unless game_id?

    if game&.association(:game_results)&.loaded?
      game.game_results.reject { |result| same_result?(result) }
    else
      GameResult.where(game_id: game_id).where.not(id: id)
    end
  end

  def same_result?(result)
    return result.equal?(self) unless persisted? && result.persisted?

    result.id == id
  end
end
