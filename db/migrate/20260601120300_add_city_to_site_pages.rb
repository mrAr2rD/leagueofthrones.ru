class AddCityToSitePages < ActiveRecord::Migration[8.1]
  def up
    add_reference :site_pages, :city, foreign_key: true # пока nullable — для бэкфилла

    moscow_id = select_value("SELECT id FROM cities WHERE slug = 'moscow'")
    raise ActiveRecord::IrreversibleMigration, "Город 'moscow' не найден" unless moscow_id

    execute("UPDATE site_pages SET city_id = #{moscow_id} WHERE city_id IS NULL")
    change_column_null :site_pages, :city_id, false

    # slug теперь уникален в пределах города (у каждого города свои «Правила»).
    remove_index :site_pages, name: "index_site_pages_on_slug"
    add_index :site_pages, [ :city_id, :slug ], unique: true
  end

  def down
    remove_index :site_pages, column: [ :city_id, :slug ]
    add_index :site_pages, :slug, unique: true
    remove_reference :site_pages, :city, foreign_key: true
  end
end
