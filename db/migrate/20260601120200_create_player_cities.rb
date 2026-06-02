class CreatePlayerCities < ActiveRecord::Migration[8.1]
  def up
    create_table :player_cities do |t|
      t.references :player, null: false, foreign_key: true
      t.references :city, null: false, foreign_key: true

      t.timestamps
    end
    add_index :player_cities, [ :player_id, :city_id ], unique: true

    # Все существующие игроки попадают в город по умолчанию.
    moscow_id = select_value("SELECT id FROM cities WHERE slug = 'moscow'")
    raise ActiveRecord::IrreversibleMigration, "Город 'moscow' не найден" unless moscow_id

    execute(<<~SQL.squish)
      INSERT INTO player_cities (player_id, city_id, created_at, updated_at)
      SELECT id, #{moscow_id}, NOW(), NOW() FROM players
    SQL
  end

  def down
    drop_table :player_cities
  end
end
