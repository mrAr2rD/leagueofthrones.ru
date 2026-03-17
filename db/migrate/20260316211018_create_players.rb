class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :nickname, null: false
      t.integer :previous_rank

      t.timestamps
    end

    add_index :players, :nickname, unique: true
  end
end
