class AddUniqueIndexForGameResultHouses < ActiveRecord::Migration[8.1]
  def change
    add_index :game_results, [ :game_id, :house ],
              unique: true,
              where: "house IS NOT NULL",
              name: "index_game_results_on_game_id_and_house"
  end
end
