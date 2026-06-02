class AddAdminAccessControls < ActiveRecord::Migration[8.1]
  def up
    add_column :admin_users, :superadmin, :boolean, default: false, null: false
    # Существующие админы имели полный доступ — делаем их супер-админами,
    # чтобы никого не заблокировать после деплоя.
    execute("UPDATE admin_users SET superadmin = TRUE")

    create_table :admin_user_cities do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.references :city, null: false, foreign_key: true

      t.timestamps
    end
    add_index :admin_user_cities, [ :admin_user_id, :city_id ], unique: true
  end

  def down
    drop_table :admin_user_cities
    remove_column :admin_users, :superadmin
  end
end
