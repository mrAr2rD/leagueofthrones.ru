class AddDateRangeToTours < ActiveRecord::Migration[8.1]
  def change
    add_column :tours, :starts_on, :date
    add_column :tours, :ends_on, :date
  end
end
