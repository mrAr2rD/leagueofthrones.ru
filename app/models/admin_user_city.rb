class AdminUserCity < ApplicationRecord
  belongs_to :admin_user
  belongs_to :city

  validates :admin_user_id, uniqueness: { scope: :city_id }
end
