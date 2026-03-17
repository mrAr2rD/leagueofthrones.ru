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

ActiveRecord::Schema[8.1].define(version: 2026_03_16_220011) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "login", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["login"], name: "index_admin_users_on_login", unique: true
  end

  create_table "game_results", force: :cascade do |t|
    t.integer "capitals", default: 0, null: false
    t.integer "castles", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "dragons", default: 0, null: false
    t.bigint "game_id", null: false
    t.integer "place", null: false
    t.bigint "player_id", null: false
    t.integer "points"
    t.datetime "updated_at", null: false
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

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name", null: false
    t.string "last_name"
    t.string "nickname", null: false
    t.integer "previous_rank"
    t.datetime "updated_at", null: false
    t.index ["nickname"], name: "index_players_on_nickname", unique: true
  end

  create_table "site_pages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_site_pages_on_slug", unique: true
  end

  create_table "tours", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "number", null: false
    t.date "played_on"
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_tours_on_number", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "game_results", "games"
  add_foreign_key "game_results", "players"
  add_foreign_key "games", "tours"
end
