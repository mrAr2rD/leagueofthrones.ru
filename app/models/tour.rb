class Tour < ApplicationRecord
  has_many :games, dependent: :destroy
  has_many :game_results, through: :games

  validates :number, presence: true, uniqueness: true,
            numericality: { in: 1..8, only_integer: true }

  scope :ordered, -> { order(:number) }
  scope :played, -> { where(played: true) }

  # Автоматически: нет даты → не сыграно
  before_validation :unplay_if_no_date

  def display_name
    "Тур #{number}"
  end

  private

  def unplay_if_no_date
    self.played = false if played_on.blank?
  end
end
