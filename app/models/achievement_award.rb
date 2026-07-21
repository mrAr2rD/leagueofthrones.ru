class AchievementAward < ApplicationRecord
  belongs_to :city
  belongs_to :player
  belongs_to :awarded_by,
             class_name: "AdminUser",
             inverse_of: :awarded_achievement_awards,
             optional: true

  scope :published, -> { where.not(published_at: nil) }
  scope :for_tournament, ->(city:, game_format:) { where(city: city, game_format: game_format.to_s) }

  validates :game_format, inclusion: { in: GameFormat.keys }
  validates :achievement_key, inclusion: { in: AchievementDefinition.keys }
  validates :stat_value,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :awarded_at, presence: true
  validates :player_id,
            uniqueness: {
              scope: [ :city_id, :game_format, :achievement_key ],
              message: "уже получил эту награду в выбранном турнире"
            }
  validate :achievement_applies_to_game_format

  def definition
    AchievementDefinition.fetch(achievement_key)
  end

  def game_format_definition
    GameFormat::FORMATS.fetch(game_format)
  end

  private

  def achievement_applies_to_game_format
    definition = AchievementDefinition.find(achievement_key)
    format = GameFormat::FORMATS[game_format]
    return if definition.nil? || format.nil? || definition.applicable_to?(format)

    errors.add(:achievement_key, "не применяется к выбранному игровому формату")
  end
end
