class CreateGameResults < ActiveRecord::Migration[8.1]
  def change
    create_table :game_results do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :place, null: false
      t.integer :points
      t.integer :capitals, default: 0, null: false
      t.integer :dragons, default: 0, null: false
      t.integer :castles, default: 0, null: false

      t.timestamps
    end

    add_index :game_results, [ :game_id, :player_id ], unique: true
  end
end
