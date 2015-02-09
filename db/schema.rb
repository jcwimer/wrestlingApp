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

ActiveRecord::Schema.define(version: 20150209154145) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "matches", force: :cascade do |t|
    t.integer  "r_id"
    t.integer  "g_id"
    t.text     "g_stat"
    t.text     "r_stat"
    t.integer  "winner_id"
    t.string   "win_type",      limit: 255
    t.string   "score",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tournament_id"
    t.integer  "round"
    t.integer  "finished"
    t.integer  "boutNumber"
  end

  create_table "mats", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "tournament_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "schools", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tournament_id"
    t.integer  "score"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "address",        limit: 255
    t.string   "director",       limit: 255
    t.string   "director_email", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "weights", force: :cascade do |t|
    t.integer  "max"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tournament_id"
  end

  create_table "wrestlers", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "school_id"
    t.integer  "weight_id"
    t.integer  "seed"
    t.integer  "original_seed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "season_win"
    t.integer  "season_loss"
    t.string   "criteria",      limit: 255
    t.integer  "poolNumber"
    t.boolean  "extra"
  end

end
