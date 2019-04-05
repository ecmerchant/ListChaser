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

ActiveRecord::Schema.define(version: 2019_04_05_150746) do

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
    t.string "rakuten_app_id"
    t.string "listing_report_id"
    t.string "inventory_report_id"
    t.datetime "listing_uploaded_at"
    t.datetime "inventory_uploaded_at"
    t.string "shop_id", default: "1"
    t.string "progress"
  end

  create_table "condition_notes", force: :cascade do |t|
    t.string "user"
    t.integer "number"
    t.text "content"
    t.string "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "converters", force: :cascade do |t|
    t.text "keyword"
    t.string "key_type"
    t.string "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["keyword", "product_id"], name: "for_upsert_converters", unique: true
  end

  create_table "items", force: :cascade do |t|
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
    t.boolean "availability", default: true
    t.string "condition"
    t.index ["item_id"], name: "for_upsert_items", unique: true
  end

  create_table "list_templates", force: :cascade do |t|
    t.string "user"
    t.string "list_type"
    t.string "header"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lists", force: :cascade do |t|
    t.string "user"
    t.string "item_id"
    t.string "product_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "profit"
    t.integer "price"
    t.integer "point"
    t.string "condition"
    t.text "condition_note"
    t.string "shop_id"
    t.index ["user", "item_id"], name: "for_upsert_lists", unique: true
  end

  create_table "prices", force: :cascade do |t|
    t.string "user"
    t.integer "original_price"
    t.integer "convert_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.string "product_id"
    t.text "name"
    t.string "image"
    t.string "url"
    t.integer "cart_price"
    t.integer "cart_shipping"
    t.integer "cart_point"
    t.integer "new_price"
    t.integer "new_shipping"
    t.integer "new_point"
    t.integer "used_price"
    t.integer "used_shipping"
    t.integer "used_point"
    t.float "amazon_fee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "for_upsert_products", unique: true
  end

  create_table "rakuten_searches", force: :cascade do |t|
    t.string "user"
    t.text "keyword"
    t.string "shop_code"
    t.string "item_code"
    t.string "genre_id"
    t.string "tag_id"
    t.string "sort"
    t.integer "min_price"
    t.integer "max_price"
    t.text "ng_keyword"
    t.integer "postage_flag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "yahoo_auc_searches", force: :cascade do |t|
    t.string "user"
    t.text "search_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
