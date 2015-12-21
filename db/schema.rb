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

ActiveRecord::Schema.define(version: 20151221031722) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "experiments", force: :cascade do |t|
    t.string   "variable"
    t.integer  "users_to_assign"
    t.datetime "end_date"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.text     "notes"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "child_birthdate"
    t.integer  "child_age",            default: 4
    t.string   "child_name"
    t.string   "carrier"
    t.integer  "story_number",         default: 0
    t.boolean  "subscribed",           default: true
    t.boolean  "mms",                  default: true
    t.integer  "last_feedback",        default: -1
    t.integer  "days_per_week"
    t.boolean  "set_time",             default: false
    t.boolean  "set_birthdate",        default: false
    t.integer  "series_number",        default: 0
    t.string   "series_choice"
    t.integer  "next_index_in_series"
    t.boolean  "awaiting_choice",      default: false
    t.boolean  "sample",               default: false
    t.integer  "total_messages",       default: 0
    t.time     "time"
    t.boolean  "on_break",             default: false
    t.integer  "days_left_on_break"
    t.string   "locale"
    t.integer  "variation_id"
  end

  add_index "users", ["variation_id"], name: "index_users_on_variation_id", using: :btree

  create_table "variations", force: :cascade do |t|
    t.integer  "experiment_id"
    t.integer  "user_id"
    t.string   "option"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "users_id"
    t.datetime "date_option"
  end

  add_index "variations", ["experiment_id"], name: "index_variations_on_experiment_id", using: :btree
  add_index "variations", ["user_id"], name: "index_variations_on_user_id", using: :btree
  add_index "variations", ["users_id"], name: "index_variations_on_users_id", using: :btree

end
