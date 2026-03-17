class CreateTours < ActiveRecord::Migration[8.1]
  def change
    create_table :tours do |t|
      t.integer :number, null: false
      t.date :played_on

      t.timestamps
    end

    add_index :tours, :number, unique: true
  end
end
