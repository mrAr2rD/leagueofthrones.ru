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
  PLACE_POINTS = { 1 => 12, 2 => 7, 3 => 6, 4 => 5, 5 => 4, 6 => 3, 7 => 2, 8 => 1 }.freeze
  TABLE_A_BONUS_PLACES = [ 1, 2, 3 ].freeze
  MAX_CAPITAL_POINTS = 3
  MAX_CASTLES_POINTS = 5

  belongs_to :game
  belongs_to :player

  validates :place, numericality: { in: 1..8, only_integer: true }, allow_nil: true
  validates :points, numericality: { only_integer: true }, allow_nil: true
  validates :capitals, :dragons, :castles,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :capital_captures, :capital_controls, :lands, :skulls,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :house,
            presence: { message: "должен быть выбран для занятого слота" },
            if: :player_id?
  validates :house,
            inclusion: { in: HOUSE_LABELS.keys, message: "выбран некорректно" },
            allow_blank: true
  validate :player_unique_within_game
  validate :player_unique_within_tour
  validate :house_unique_within_game
  validate :house_unique_for_player

  def self.house_options
    HOUSE_OPTIONS
  end

  def self.house_options_for(used_houses: [])
    used_houses = Array(used_houses)
    HOUSE_OPTIONS.reject { |(_label, key)| used_houses.include?(key) }
  end

  def self.effective_capitals(capitals:, capital_captures: nil, capital_controls: nil)
    return capitals.to_i if capital_captures.nil? && capital_controls.nil?

    capital_captures.to_i + capital_controls.to_i
  end

  def self.capital_points(capitals:, capital_captures: nil, capital_controls: nil)
    [ effective_capitals(
      capitals: capitals,
      capital_captures: capital_captures,
      capital_controls: capital_controls
    ), MAX_CAPITAL_POINTS ].min
  end

  def self.ranking_captures(capitals:, capital_captures: nil, capital_controls: nil)
    return capitals.to_i if capital_captures.nil? && capital_controls.nil?

    capital_captures.to_i
  end

  def self.calculate_points(place:, capitals: 0, capital_captures: nil, capital_controls: nil, dragons:, castles:, table_letter:)
    normalized_place = place.to_i
    return nil if normalized_place <= 0

    place_points = PLACE_POINTS.fetch(normalized_place, 0)
    table_bonus = table_letter == "A" && TABLE_A_BONUS_PLACES.include?(normalized_place) ? 1 : 0

    place_points + table_bonus +
      capital_points(
        capitals: capitals,
        capital_captures: capital_captures,
        capital_controls: capital_controls
      ) +
      dragons.to_i +
      [ castles.to_i, MAX_CASTLES_POINTS ].min
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
      capital_controls: capital_controls
    )
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
      table_letter: game&.table_letter
    )
  end

  def player_unique_within_game
    return unless player_id? && game_id?
    return unless sibling_results.any? { |result| result.player_id == player_id }

    errors.add(:player_id, "уже выбран за этим столом")
  end

  def player_unique_within_tour
    return unless player_id? && game&.tour_id

    duplicate_in_other_games = GameResult.joins(:game)
                                         .where(player_id: player_id, games: { tour_id: game.tour_id })
                                         .where.not(game_id: game_id)
                                         .where.not(id: id)
                                         .exists?
    return unless duplicate_in_other_games

    errors.add(:player_id, "уже выбран за другим столом этого тура")
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
    duplicate_in_other_games = GameResult.where(player_id: player_id, house: house)
                                         .where.not(game_id: game_id)
                                         .where.not(id: id)
                                         .exists?
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
