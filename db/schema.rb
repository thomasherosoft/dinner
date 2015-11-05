# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20151105105031) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cuisines", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cuisines_restaurants", id: false, force: :cascade do |t|
    t.integer "cuisine_id",    null: false
    t.integer "restaurant_id", null: false
  end

  add_index "cuisines_restaurants", ["restaurant_id"], name: "index_cuisines_restaurants_on_restaurant_id", using: :btree

  create_table "restaurants", force: :cascade do |t|
    t.string   "name",                                 null: false
    t.string   "address"
    t.string   "phone"
    t.string   "city"
    t.string   "area"
    t.decimal  "latitude"
    t.decimal  "longitude"
    t.string   "zipcode"
    t.integer  "price_range"
    t.string   "price_range_currency"
    t.integer  "rating"
    t.string   "zomato_id"
    t.datetime "zomato_fetched_at"
    t.string   "zagat_status"
    t.string   "michelin_status"
    t.string   "timeout_status"
    t.string   "foodtruck_status"
    t.string   "faisal_status"
    t.string   "deliveroo_status"
    t.string   "google_place_id"
    t.string   "zomato_url"
    t.integer  "reviews_count",        default: 0,     null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "newly_opened",         default: false, null: false
    t.string   "website"
    t.string   "photoid"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer  "restaurant_id", null: false
    t.string   "source",        null: false
    t.string   "content",       null: false
    t.string   "url"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "reviews", ["restaurant_id"], name: "index_reviews_on_restaurant_id", using: :btree
  add_index "reviews", ["source"], name: "index_reviews_on_source", using: :btree

  create_table "searches", force: :cascade do |t|
    t.text     "log_line"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
