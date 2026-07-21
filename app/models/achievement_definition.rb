class AchievementDefinition
  Definition = Struct.new(
    :key,
    :name,
    :icon_path,
    :description,
    :metric,
    :applicability,
    :secret,
    keyword_init: true
  ) do
    def applicable_to?(format)
      return true if applicability == :all

      format.public_send(applicability)
    end

    def secret?
      secret
    end
  end

  DEFINITIONS = [
    Definition.new(
      key: "conqueror",
      name: "Завоеватель",
      icon_path: "achievements/conqueror.png",
      description: "Больше всего захваченных чужих столиц с гарнизоном за турнир",
      metric: :captures,
      applicability: :all,
      secret: false
    ),
    Definition.new(
      key: "dragon_slayer",
      name: "Драконоборец",
      icon_path: "achievements/dragon_slayer.png",
      description: "Больше всего убитых драконов за турнир",
      metric: :dragons,
      applicability: :tracks_dragons?,
      secret: false
    ),
    Definition.new(
      key: "faceless_chosen",
      name: "Избранник Безликих",
      icon_path: "achievements/faceless_chosen.png",
      description: "Больше всего вытянул знаков черепа на картах Перевеса за турнир",
      metric: :skulls,
      applicability: :tracks_skulls?,
      secret: true
    )
  ].each(&:freeze).freeze

  BY_KEY = DEFINITIONS.index_by(&:key).freeze

  class << self
    def all
      DEFINITIONS
    end

    def keys
      BY_KEY.keys
    end

    def find(key)
      BY_KEY[key.to_s]
    end

    def fetch(key)
      BY_KEY.fetch(key.to_s)
    end

    def for_format(format)
      game_format = normalize_format(format)
      all.select { |definition| definition.applicable_to?(game_format) }
    end

    private

    def normalize_format(format)
      return format if format.is_a?(GameFormat)

      GameFormat::FORMATS.fetch(format.to_s)
    end
  end
end
