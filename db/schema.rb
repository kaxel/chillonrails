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

ActiveRecord::Schema[8.0].define(version: 2026_08_02_045800) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "playlists", force: :cascade do |t|
    t.string "name"
    t.jsonb "songs"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_playlists_on_slug", unique: true
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

  create_table "submission_songs", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_submission_songs_on_submission_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.string "contact_name", null: false
    t.string "email", null: false
    t.string "artist_name", null: false
    t.string "status", default: "pending", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "stripe_session_id"
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_submissions_on_status"
    t.index ["stripe_session_id"], name: "index_submissions_on_stripe_session_id", unique: true
    t.index ["token"], name: "index_submissions_on_token", unique: true
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
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.string "provider"
    t.string "uid"
    t.string "profile_image"
    t.boolean "admin", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "submission_songs", "submissions"
end
