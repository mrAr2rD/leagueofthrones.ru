class AddPlayedToTours < ActiveRecord::Migration[8.1]
  def change
    add_column :tours, :played, :boolean, default: false, null: false
  end
end
