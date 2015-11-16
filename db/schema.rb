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

ActiveRecord::Schema.define(version: 20151111130227) do

  create_table "matches", force: :cascade do |t|
    t.integer  "w1"
    t.integer  "w2"
    t.text     "g_stat"
    t.text     "r_stat"
    t.integer  "winner_id"
    t.string   "win_type"
    t.string   "score"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tournament_id"
    t.integer  "round"
    t.integer  "finished"
    t.integer  "bout_number"
    t.integer  "weight_id"
    t.string   "bracket_position"
    t.integer  "bracket_position_number"
    t.string   "loser1_name"
    t.string   "loser2_name"
    t.integer  "mat_id"
  end

  add_index "matches", ["mat_id"], name: "index_matches_on_mat_id"
  add_index "matches", ["tournament_id"], name: "index_matches_on_tournament_id"
  add_index "matches", ["w1", "w2"], name: "index_matches_on_w1_and_w2"

  create_table "mats", force: :cascade do |t|
    t.string   "name"
    t.integer  "tournament_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mats", ["tournament_id"], name: "index_mats_on_tournament_id"

  create_table "schools", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tournament_id"
  end

  add_index "schools", ["tournament_id"], name: "index_schools_on_tournament_id"

  create_table "teampointadjusts", force: :cascade do |t|
    t.integer  "points"
    t.integer  "wrestler_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "teampointadjusts", ["wrestler_id"], name: "index_teampointadjusts_on_wrestler_id"

  create_table "tournaments", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.string   "director"
    t.string   "director_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "tournament_type"
    t.text     "weigh_in_ref"
    t.integer  "user_id"
  end

  add_index "tournaments", ["user_id"], name: "index_tournaments_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
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

  add_index "weights", ["tournament_id"], name: "index_weights_on_tournament_id"

  create_table "wrestlers", force: :cascade do |t|
    t.string   "name"
    t.integer  "school_id"
    t.integer  "weight_id"
    t.integer  "seed"
    t.integer  "original_seed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "season_win"
    t.integer  "season_loss"
    t.string   "criteria"
    t.boolean  "extra"
    t.decimal  "offical_weight"
  end

  add_index "wrestlers", ["weight_id"], name: "index_wrestlers_on_weight_id"

end
