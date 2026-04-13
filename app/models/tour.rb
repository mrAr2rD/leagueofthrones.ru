class Tour < ApplicationRecord
  has_many :games, dependent: :destroy
  has_many :game_results, through: :games

  validates :number, presence: true, uniqueness: true,
            numericality: { in: 1..8, only_integer: true }
  validate :ends_on_after_starts_on

  scope :ordered, -> { order(:number) }
  scope :played, -> { where(played: true) }

  # Автоматически: нет даты → не сыграно
  before_validation :unplay_if_no_date

  def display_name
    "Тур #{number}"
  end

  def date_range_label
    return nil if starts_on.blank? && ends_on.blank?

    if starts_on.present? && ends_on.present?
      "#{starts_on.strftime('%d.%m')} – #{ends_on.strftime('%d.%m')}"
    elsif starts_on.present?
      starts_on.strftime('%d.%m')
    else
      ends_on.strftime('%d.%m')
    end
  end

  private

  def unplay_if_no_date
    self.played = false if played_on.blank?
  end

  def ends_on_after_starts_on
    return if starts_on.blank? || ends_on.blank?

    errors.add(:ends_on, "должна быть не раньше даты начала") if ends_on < starts_on
  end
end
