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

ActiveRecord::Schema.define(version: 20191128002659) do

  create_table "events", force: :cascade do |t|
    t.string   "event_type"
    t.datetime "time_start"
    t.datetime "time_end"
    t.string   "player_affected"
    t.integer  "player_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "events", ["player_id"], name: "index_events_on_player_id"

  create_table "players", force: :cascade do |t|
    t.string   "name"
    t.string   "role"
    t.string   "visiting"
    t.string   "activity"
    t.integer  "score"
    t.integer  "lives"
    t.string   "last_round_notice"
    t.integer  "round"
    t.integer  "room_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "players", ["room_id"], name: "index_players_on_room_id"

  create_table "rooms", force: :cascade do |t|
    t.string   "code"
    t.string   "leader"
    t.integer  "robber_count"
    t.integer  "farmer_count"
    t.integer  "investigator_count"
    t.integer  "donator_count"
    t.integer  "round"
    t.integer  "number_of_rounds"
    t.string   "participants"
    t.integer  "round_end"
    t.integer  "time_per_round"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

end
