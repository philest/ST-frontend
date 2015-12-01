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

ActiveRecord::Schema.define(version: 20150802023253) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "users", force: :cascade do |t|       #an enrolled parent 
    t.string   "name"                                #first, last 
    t.string   "phone"                               #+15614445555 
    t.datetime "created_at"                          #timestamp
    t.datetime "updated_at"                          #timestamp
    t.string   "child_birthdate"                     #TO REMOVE
    t.integer  "child_age",            default: 4    #TO REMOVE
    t.string   "child_name"                          #TO REMOVE
    t.string   "carrier"                             #ie Sprint (from Twilio lookup) 
    t.integer  "story_number",         default: 0    #how many *non-chosen* stories received?
    t.boolean  "subscribed",           default: true #receiving stories?
    t.boolean  "mms",                  default: true #can receive MMS? 
    t.integer  "last_feedback",        default: -1   #TO REMOVE
    t.integer  "days_per_week"                       #how many days/week
    t.boolean  "set_time",             default: false#TO REMOVE
    t.boolean  "set_birthdate",        default: false#TO REMOVE
    t.integer  "series_number",        default: 0    #how many *chosen* series (1 or more episodes) received?
    t.string   "series_choice"                       #first letter of choice ('t')
    t.integer  "next_index_in_series"                #how many episodes of one *chosen* series received? 
    t.boolean  "awaiting_choice",      default: false#waiting for parent reply with letter choice? 
    t.boolean  "sample",               default: false#user isn't subscribed; just got SAMPLE
    t.integer  "total_messages",       default: 0    #how many stories (+series episodes) sent total
    t.time     "time"                                #time in UCT to stories
    t.boolean  "on_break",             default: false#on 2 week break from BREAK?
    t.integer  "days_left_on_break"                  #how many days left?
    t.string   "locale"                              #language ('en' or 'es')
  end

end
