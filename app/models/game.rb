class Game < ApplicationRecord
  TABLE_LETTERS = %w[A B C D].freeze

  belongs_to :tour
  has_many :game_results, dependent: :destroy

  validates :table_letter, presence: true, inclusion: { in: TABLE_LETTERS }
  validates :table_letter, uniqueness: { scope: :tour_id }

  scope :ordered, -> { order(:table_letter) }

  def display_name
    "Стол #{table_letter}"
  end
end
