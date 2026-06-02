class AdminUser < ApplicationRecord
  has_secure_password

  has_many :admin_user_cities, dependent: :destroy
  has_many :cities, through: :admin_user_cities

  validates :login, presence: true, uniqueness: true

  # Города, к которым у админа есть доступ. Супер-админ видит все.
  def accessible_cities
    superadmin? ? City.ordered : cities.ordered
  end

  def can_access_city?(city)
    return false if city.nil?

    superadmin? || cities.exists?(city.id)
  end
end
