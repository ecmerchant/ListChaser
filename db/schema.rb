# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_02_17_155127) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "user"
    t.string "seller_id"
    t.string "mws_auth_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_item_num", default: 0
    t.integer "max_page", default: 10
    t.integer "max_item_num", default: 100
  end

  create_table "items", force: :cascade do |t|
    t.string "user"
    t.string "item_id"
    t.string "shop_id"
    t.string "url"
    t.text "name"
    t.string "jan"
    t.string "mpn"
    t.integer "price"
    t.string "image"
    t.text "description"
    t.string "category_id"
    t.text "keyword"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user", "item_id"], name: "for_upsert_items", unique: true
  end

  create_table "shops", force: :cascade do |t|
    t.integer "shop_id"
    t.text "name"
    t.string "root"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin_flg"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
