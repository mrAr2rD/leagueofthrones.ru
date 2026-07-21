class City < ApplicationRecord
  has_many :tours, dependent: :destroy
  has_many :site_pages, dependent: :destroy
  has_many :player_cities, dependent: :destroy
  has_many :players, through: :player_cities
  has_many :admin_user_cities, dependent: :destroy
  has_many :admin_users, through: :admin_user_cities
  has_many :achievement_awards, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9-]+\z/, message: "только латиница, цифры и дефис" }
  validates :default_format, inclusion: { in: GameFormat.keys }

  scope :ordered, -> { order(:position, :name) }

  # У каждого города должна быть страница «Правила» (иначе /:city/rules → 404).
  after_create :create_default_rules_page

  def default_game_format
    GameFormat.find(default_format)
  end

  def to_param
    slug
  end

  private

  def create_default_rules_page
    site_pages.create!(slug: "rules", title: "Регламент турнира", content: "Регламент скоро появится.")
  end
end
