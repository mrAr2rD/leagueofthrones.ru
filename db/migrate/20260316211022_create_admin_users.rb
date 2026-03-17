class CreateAdminUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_users do |t|
      t.string :login, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :admin_users, :login, unique: true
  end
end
