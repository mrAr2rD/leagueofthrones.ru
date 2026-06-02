class AddCityAndFormatToTours < ActiveRecord::Migration[8.1]
  def up
    # format с дефолтом сразу бэкфиллит существующие строки.
    add_column :tours, :format, :string, null: false, default: "mother_of_dragons"
    add_reference :tours, :city, foreign_key: true # пока nullable — для бэкфилла

    moscow_id = select_value("SELECT id FROM cities WHERE slug = 'moscow'")
    raise ActiveRecord::IrreversibleMigration, "Город 'moscow' не найден" unless moscow_id

    execute("UPDATE tours SET city_id = #{moscow_id} WHERE city_id IS NULL")
    change_column_null :tours, :city_id, false

    # Номер тура теперь уникален в пределах города, а не глобально.
    remove_index :tours, name: "index_tours_on_number"
    add_index :tours, [ :city_id, :number ], unique: true
  end

  def down
    remove_index :tours, column: [ :city_id, :number ]
    add_index :tours, :number, unique: true
    remove_reference :tours, :city, foreign_key: true
    remove_column :tours, :format
  end
end
