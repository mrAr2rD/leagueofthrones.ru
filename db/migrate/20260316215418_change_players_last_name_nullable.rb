class ChangePlayersLastNameNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :players, :last_name, true
  end
end
