class Player < ApplicationRecord
  has_many :game_results, dependent: :destroy
  has_one_attached :photo

  validates :first_name, :nickname, presence: true
  validates :nickname, uniqueness: true

  def display_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def nickname_handle
    return if nickname.blank?

    nickname.start_with?("@") ? nickname : "@#{nickname}"
  end

  def admin_option_label
    return display_name if nickname_handle.blank?

    "#{display_name} (#{nickname_handle})"
  end

  def initials
    parts = [first_name, last_name].compact_blank
    parts.map { |p| p[0] }.join
  end

  def photo_thumbnail
    photo.variant(resize_to_fill: [ 40, 40 ])
  end

  def photo_large
    photo.variant(resize_to_fill: [ 200, 200 ])
  end
end
