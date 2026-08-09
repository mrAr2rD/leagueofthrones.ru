# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_09_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "achievement_awards", force: :cascade do |t|
    t.string "achievement_key", null: false
    t.datetime "awarded_at", null: false
    t.bigint "awarded_by_id"
    t.bigint "city_id", null: false
    t.datetime "created_at", null: false
    t.string "game_format", null: false
    t.bigint "player_id", null: false
    t.datetime "published_at"
    t.integer "stat_value", null: false
    t.datetime "updated_at", null: false
    t.index ["awarded_by_id"], name: "index_achievement_awards_on_awarded_by_id"
    t.index ["city_id", "game_format", "achievement_key", "player_id"], name: "index_achievement_awards_tournament_winner_unique", unique: true
    t.index ["city_id"], name: "index_achievement_awards_on_city_id"
    t.index ["player_id"], name: "index_achievement_awards_on_player_id"
    t.check_constraint "stat_value >= 0", name: "achievement_awards_stat_value_nonnegative"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_user_cities", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.bigint "city_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "city_id"], name: "index_admin_user_cities_on_admin_user_id_and_city_id", unique: true
    t.index ["admin_user_id"], name: "index_admin_user_cities_on_admin_user_id"
    t.index ["city_id"], name: "index_admin_user_cities_on_city_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "login", null: false
    t.string "password_digest", null: false
    t.boolean "superadmin", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["login"], name: "index_admin_users_on_login", unique: true
  end

  create_table "cities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_format", default: "mother_of_dragons", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "register_url"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_cities_on_slug", unique: true
  end

  create_table "game_results", force: :cascade do |t|
    t.integer "capital_captures"
    t.integer "capital_controls"
    t.integer "capitals", default: 0, null: false
    t.integer "castles", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "dragons", default: 0, null: false
    t.bigint "game_id", null: false
    t.string "house"
    t.integer "lands"
    t.integer "place"
    t.bigint "player_id", null: false
    t.integer "points"
    t.integer "skulls"
    t.datetime "updated_at", null: false
    t.index ["game_id", "house"], name: "index_game_results_on_game_id_and_house", unique: true, where: "(house IS NOT NULL)"
    t.index ["game_id", "player_id"], name: "index_game_results_on_game_id_and_player_id", unique: true
    t.index ["game_id"], name: "index_game_results_on_game_id"
    t.index ["player_id"], name: "index_game_results_on_player_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "table_letter", limit: 1, null: false
    t.bigint "tour_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tour_id", "table_letter"], name: "index_games_on_tour_id_and_table_letter", unique: true
    t.index ["tour_id"], name: "index_games_on_tour_id"
  end

  create_table "player_cities", force: :cascade do |t|
    t.bigint "city_id", null: false
    t.datetime "created_at", null: false
    t.bigint "player_id", null: false
    t.integer "previous_rank"
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_player_cities_on_city_id"
    t.index ["player_id", "city_id"], name: "index_player_cities_on_player_id_and_city_id", unique: true
    t.index ["player_id"], name: "index_player_cities_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name", null: false
    t.string "last_name"
    t.string "nickname", null: false
    t.boolean "participates_in_tournament", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["nickname"], name: "index_players_on_nickname", unique: true
  end

  create_table "site_pages", force: :cascade do |t|
    t.bigint "city_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["city_id", "slug"], name: "index_site_pages_on_city_id_and_slug", unique: true
    t.index ["city_id"], name: "index_site_pages_on_city_id"
  end

  create_table "tides_of_battle_sessions", force: :cascade do |t|
    t.string "attacker_card"
    t.bigint "city_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "deck_order", default: [], null: false
    t.string "defender_card"
    t.string "rerolled_side"
    t.datetime "revealed_at"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_tides_of_battle_sessions_on_city_id"
    t.index ["token"], name: "index_tides_of_battle_sessions_on_token", unique: true
  end

  create_table "tours", force: :cascade do |t|
    t.bigint "city_id", null: false
    t.datetime "created_at", null: false
    t.date "ends_on"
    t.string "format", default: "mother_of_dragons", null: false
    t.integer "number", null: false
    t.boolean "played", default: false, null: false
    t.date "played_on"
    t.date "starts_on"
    t.integer "tables_count", default: 4, null: false
    t.datetime "updated_at", null: false
    t.index ["city_id", "number"], name: "index_tours_on_city_id_and_number", unique: true
    t.index ["city_id"], name: "index_tours_on_city_id"
  end

  add_foreign_key "achievement_awards", "admin_users", column: "awarded_by_id", on_delete: :nullify
  add_foreign_key "achievement_awards", "cities"
  add_foreign_key "achievement_awards", "players"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_user_cities", "admin_users"
  add_foreign_key "admin_user_cities", "cities"
  add_foreign_key "game_results", "games"
  add_foreign_key "game_results", "players"
  add_foreign_key "games", "tours"
  add_foreign_key "player_cities", "cities"
  add_foreign_key "player_cities", "players"
  add_foreign_key "site_pages", "cities"
  add_foreign_key "tides_of_battle_sessions", "cities"
  add_foreign_key "tours", "cities"
end
