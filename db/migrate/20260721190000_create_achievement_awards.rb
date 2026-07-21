class CreateAchievementAwards < ActiveRecord::Migration[8.1]
  def change
    create_table :achievement_awards do |t|
      t.references :city, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string :game_format, null: false
      t.string :achievement_key, null: false
      t.integer :stat_value, null: false
      t.datetime :awarded_at, null: false
      t.datetime :published_at
      t.references :awarded_by,
                   null: true,
                   foreign_key: { to_table: :admin_users, on_delete: :nullify }

      t.timestamps
    end

    add_index :achievement_awards,
              [ :city_id, :game_format, :achievement_key, :player_id ],
              unique: true,
              name: "index_achievement_awards_tournament_winner_unique"
    add_check_constraint :achievement_awards,
                         "stat_value >= 0",
                         name: "achievement_awards_stat_value_nonnegative"
  end
end
