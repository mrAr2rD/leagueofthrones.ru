class AddSplitBonusFieldsToGameResults < ActiveRecord::Migration[8.1]
  def change
    change_table :game_results, bulk: true do |t|
      t.integer :capital_captures
      t.integer :capital_controls
      t.integer :lands
      t.integer :skulls
    end
  end
end
