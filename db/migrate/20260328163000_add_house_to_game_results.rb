class AddHouseToGameResults < ActiveRecord::Migration[8.1]
  def change
    add_column :game_results, :house, :string
  end
end
