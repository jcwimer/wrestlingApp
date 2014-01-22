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

ActiveRecord::Schema.define(version: 20140121020833) do

  create_table "schools", force: true do |t|
    t.string   "name"
    t.integer  "score"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tournament_id"
  end

  create_table "tournaments", force: true do |t|
    t.string   "name"
    t.string   "address"
    t.string   "director"
    t.string   "director_email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "weights", force: true do |t|
    t.integer  "max"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wrestlers", force: true do |t|
    t.string   "name"
    t.integer  "school_id"
    t.integer  "weight_id"
    t.integer  "seed"
    t.integer  "original_seed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
