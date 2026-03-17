class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.references :tour, null: false, foreign_key: true
      t.string :table_letter, limit: 1, null: false

      t.timestamps
    end

    add_index :games, [ :tour_id, :table_letter ], unique: true
  end
end
