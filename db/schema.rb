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

ActiveRecord::Schema[8.0].define(version: 2025_04_15_173921) do
  create_table "mat_assignment_rules", force: :cascade do |t|
    t.bigint "tournament_id"
    t.bigint "mat_id"
    t.string "weight_classes"
    t.string "bracket_positions"
    t.string "rounds"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mat_id"], name: "index_mat_assignment_rules_on_mat_id", unique: true
    t.index ["tournament_id"], name: "index_mat_assignment_rules_on_tournament_id"
  end

  create_table "matches", force: :cascade do |t|
    t.integer "w1"
    t.integer "w2"
    t.text "w1_stat"
    t.text "w2_stat"
    t.integer "winner_id"
    t.string "win_type"
    t.string "score"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "tournament_id"
    t.integer "round"
    t.integer "finished"
    t.integer "bout_number"
    t.bigint "weight_id"
    t.string "bracket_position"
    t.integer "bracket_position_number"
    t.string "loser1_name"
    t.string "loser2_name"
    t.bigint "mat_id"
    t.string "overtime_type"
    t.datetime "finished_at"
    t.index ["mat_id"], name: "index_matches_on_mat_id"
    t.index ["tournament_id"], name: "index_matches_on_tournament_id"
    t.index ["w1", "w2"], name: "index_matches_on_w1_and_w2"
    t.index ["weight_id"], name: "index_matches_on_weight_id"
  end

  create_table "mats", force: :cascade do |t|
    t.string "name"
    t.bigint "tournament_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["tournament_id"], name: "index_mats_on_tournament_id"
  end

  create_table "school_delegates", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "school_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["school_id"], name: "index_school_delegates_on_school_id"
    t.index ["user_id"], name: "index_school_delegates_on_user_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "tournament_id"
    t.decimal "score", precision: 15, scale: 1
    t.string "permission_key"
    t.index ["permission_key"], name: "index_schools_on_permission_key", unique: true
    t.index ["tournament_id"], name: "index_schools_on_tournament_id"
  end

  create_table "teampointadjusts", force: :cascade do |t|
    t.integer "points"
    t.bigint "wrestler_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "school_id"
    t.index ["school_id"], name: "index_teampointadjusts_on_school_id"
    t.index ["wrestler_id"], name: "index_teampointadjusts_on_wrestler_id"
  end

  create_table "tournament_backups", force: :cascade do |t|
    t.bigint "tournament_id"
    t.text "backup_data", limit: 4294967295, null: false
    t.string "backup_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_tournament_backups_on_tournament_id"
  end

  create_table "tournament_delegates", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "tournament_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["tournament_id"], name: "index_tournament_delegates_on_tournament_id"
    t.index ["user_id"], name: "index_tournament_delegates_on_user_id"
  end

  create_table "tournament_job_statuses", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.string "job_name", null: false
    t.string "status", default: "Queued", null: false
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id", "job_name"], name: "index_tournament_job_statuses_on_tournament_id_and_job_name"
    t.index ["tournament_id"], name: "index_tournament_job_statuses_on_tournament_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "director"
    t.string "director_email"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "tournament_type"
    t.text "weigh_in_ref"
    t.bigint "user_id"
    t.integer "curently_generating_matches"
    t.date "date"
    t.boolean "is_public"
    t.index ["user_id"], name: "index_tournaments_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "password_digest"
    t.string "reset_digest"
    t.datetime "reset_sent_at", precision: nil
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "weights", force: :cascade do |t|
    t.decimal "max", precision: 15, scale: 1
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "tournament_id"
    t.index ["tournament_id"], name: "index_weights_on_tournament_id"
  end

  create_table "wrestlers", force: :cascade do |t|
    t.string "name"
    t.bigint "school_id"
    t.bigint "weight_id"
    t.integer "bracket_line"
    t.integer "original_seed"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "season_win"
    t.integer "season_loss"
    t.string "criteria"
    t.boolean "extra"
    t.decimal "offical_weight"
    t.integer "pool"
    t.integer "pool_placement"
    t.string "pool_placement_tiebreaker"
    t.index ["school_id"], name: "index_wrestlers_on_school_id"
    t.index ["weight_id"], name: "index_wrestlers_on_weight_id"
  end

  add_foreign_key "mat_assignment_rules", "mats"
  add_foreign_key "mat_assignment_rules", "tournaments"
  add_foreign_key "matches", "mats"
  add_foreign_key "matches", "tournaments"
  add_foreign_key "matches", "weights"
  add_foreign_key "mats", "tournaments"
  add_foreign_key "school_delegates", "schools"
  add_foreign_key "school_delegates", "users"
  add_foreign_key "schools", "tournaments"
  add_foreign_key "teampointadjusts", "schools"
  add_foreign_key "teampointadjusts", "wrestlers"
  add_foreign_key "tournament_backups", "tournaments"
  add_foreign_key "tournament_delegates", "tournaments"
  add_foreign_key "tournament_delegates", "users"
  add_foreign_key "tournament_job_statuses", "tournaments"
  add_foreign_key "tournaments", "users"
  add_foreign_key "weights", "tournaments"
  add_foreign_key "wrestlers", "schools"
  add_foreign_key "wrestlers", "weights"
end
