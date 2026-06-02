class CreateCities < ActiveRecord::Migration[8.1]
  def change
    create_table :cities do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :register_url
      t.string :default_format, null: false, default: "mother_of_dragons"
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :cities, :slug, unique: true

    # Город по умолчанию, под который мигрируют все существующие данные.
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          INSERT INTO cities (name, slug, register_url, default_format, position, created_at, updated_at)
          VALUES ('Москва', 'moscow', 'https://t.me/aesmic', 'mother_of_dragons', 0, NOW(), NOW())
        SQL
      end
    end
  end
end
