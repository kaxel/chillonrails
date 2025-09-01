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

ActiveRecord::Schema[8.0].define(version: 2025_09_01_063654) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "authors", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "collection_id"
    t.string "locale_id"
    t.string "item_id"
    t.boolean "archived", default: false
    t.boolean "draft", default: false
    t.datetime "created_on"
    t.datetime "updated_on"
    t.datetime "published_on"
    t.string "author_photo"
    t.string "author_email"
    t.string "author_position"
    t.text "about_author"
    t.string "social_profile_link_1"
    t.string "social_profile_link_2"
    t.string "social_profile_link_3"
    t.boolean "editorial_chief", default: false
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_authors_on_item_id", unique: true
    t.index ["slug"], name: "index_authors_on_slug", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug"
    t.text "description"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_locations_on_name", unique: true
    t.index ["slug"], name: "index_locations_on_slug", unique: true
  end

  create_table "page_not_founds", force: :cascade do |t|
    t.string "url"
    t.datetime "accessed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug"
    t.text "content"
    t.string "image"
    t.string "video_link"
    t.string "audio_link"
    t.string "location"
    t.string "tags"
    t.text "preview"
    t.string "topic"
    t.string "author"
    t.date "published_on"
    t.date "created_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "score", default: 0, null: false
    t.integer "score_all_time", default: 0, null: false
    t.index ["score"], name: "index_posts_on_score"
    t.index ["score_all_time"], name: "index_posts_on_score_all_time"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
    t.index ["topic"], name: "index_posts_on_topic"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "sessions", "users"
end
