class AddTablesCountToTours < ActiveRecord::Migration[8.1]
  # Число столов в туре теперь настраивается (1..4). Существующие туры
  # имели 4 стола (A–D), поэтому дефолт 4 бэкфиллит их корректно.
  def change
    add_column :tours, :tables_count, :integer, default: 4, null: false
  end
end
