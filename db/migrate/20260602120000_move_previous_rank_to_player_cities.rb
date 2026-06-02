class MovePreviousRankToPlayerCities < ActiveRecord::Migration[8.1]
  # Прежний ранг хранился глобально на players.previous_rank и перетирался
  # при пересчёте каждого города. Переносим его в player_cities, чтобы
  # «прирост» (rank_change) считался отдельно по каждому городу.
  def up
    add_column :player_cities, :previous_rank, :integer
    remove_column :players, :previous_rank
  end

  def down
    add_column :players, :previous_rank, :integer
    remove_column :player_cities, :previous_rank
  end
end
