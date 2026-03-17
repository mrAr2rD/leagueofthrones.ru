class Tour < ApplicationRecord
  has_many :games, dependent: :destroy
  has_many :game_results, through: :games

  validates :number, presence: true, uniqueness: true,
            numericality: { in: 1..8, only_integer: true }

  scope :ordered, -> { order(:number) }

  def display_name
    "Тур #{number}"
  end
end
