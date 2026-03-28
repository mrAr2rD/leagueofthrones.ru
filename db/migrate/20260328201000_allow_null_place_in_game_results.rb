class AllowNullPlaceInGameResults < ActiveRecord::Migration[8.1]
  def change
    change_column_null :game_results, :place, true
  end
end
