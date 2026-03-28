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

  def suggested_points
    return 0 unless place

    base = PLACE_POINTS.fetch(place, 0)
    base + ((capitals || 0) * 2) + (dragons || 0) + (castles || 0)
  end

  def house_name
    HOUSE_LABELS[house]
  end

  private

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
