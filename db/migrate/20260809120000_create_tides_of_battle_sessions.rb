class CreateTidesOfBattleSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :tides_of_battle_sessions do |t|
      t.references :city, null: false, foreign_key: true
      t.string :token, null: false
      t.jsonb :deck_order, null: false, default: []
      t.string :attacker_card
      t.string :defender_card
      t.string :rerolled_side
      t.datetime :revealed_at

      t.timestamps
    end

    add_index :tides_of_battle_sessions, :token, unique: true
  end
end
