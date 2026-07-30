class Tour < ApplicationRecord
  belongs_to :city
  has_many :games, dependent: :destroy
  has_many :game_results, through: :games

  validates :number, presence: true,
            uniqueness: { scope: :city_id },
            numericality: { only_integer: true, greater_than: 0 }
  validates :format, inclusion: { in: GameFormat.keys }
  validates :tables_count, inclusion: { in: 1..Game::TABLE_LETTERS.size }
  validate :number_within_format
  validate :ends_on_after_starts_on

  scope :ordered, -> { order(:number) }
  scope :played, -> { where(played: true) }

  # Автоматически: нет даты → не сыграно
  before_validation :unplay_if_no_date

  # Буквы столов этого тура: A, A–B, A–D и т.п.
  def table_letters
    Game::TABLE_LETTERS.first(tables_count)
  end

  # Создаёт недостающие столы и удаляет лишние ПУСТЫЕ (столы с результатами
  # не трогаются — их удаляют вручную). Вызывается из админки при сохранении.
  def sync_tables
    wanted = table_letters
    existing = games.pluck(:table_letter)

    (wanted - existing).each { |letter| games.create!(table_letter: letter) }

    games.where.not(table_letter: wanted).each do |game|
      game.destroy if game.game_results.empty?
    end
  end

  # Формат тура задаёт правила подсчёта и число слотов.
  def game_format
    GameFormat.find(self[:format])
  end

  def final_tour?
    number == game_format.tour_default_count
  end

  def allows_house_reuse?
    game_format.key == GameFormat::DEFAULT_KEY && final_tour?
  end

  def display_name
    "Тур #{number}"
  end

  def date_range_label
    return nil if starts_on.blank? && ends_on.blank?

    if starts_on.present? && ends_on.present?
      return starts_on.strftime("%d.%m") if starts_on == ends_on

      "#{starts_on.strftime('%d.%m')} – #{ends_on.strftime('%d.%m')}"
    elsif starts_on.present?
      starts_on.strftime("%d.%m")
    else
      ends_on.strftime("%d.%m")
    end
  end

  private

  def unplay_if_no_date
    self.played = false if played_on.blank?
  end

  # Число туров ограничено форматом (Мать драконов — 8, Классика — 6).
  def number_within_format
    return if number.blank? || !number.is_a?(Integer)

    max = game_format.tour_default_count
    errors.add(:number, "должен быть от 1 до #{max} для формата «#{game_format.label}»") if number > max
  end

  def ends_on_after_starts_on
    return if starts_on.blank? || ends_on.blank?

    errors.add(:ends_on, "должна быть не раньше даты начала") if ends_on < starts_on
  end
end
