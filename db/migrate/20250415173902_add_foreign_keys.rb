class AddForeignKeys < ActiveRecord::Migration[7.0]
  def change
    # wrestlers table
    add_foreign_key :wrestlers, :schools
    add_foreign_key :wrestlers, :weights

    # weights table
    add_foreign_key :weights, :tournaments

    # tournament_delegates table
    add_foreign_key :tournament_delegates, :tournaments
    add_foreign_key :tournament_delegates, :users

    # tournaments table
    add_foreign_key :tournaments, :users

    # tournament_backups table
    add_foreign_key :tournament_backups, :tournaments

    # teampointadjusts table
    add_foreign_key :teampointadjusts, :wrestlers
    add_foreign_key :teampointadjusts, :schools

    # school_delegates table
    add_foreign_key :school_delegates, :schools
    add_foreign_key :school_delegates, :users

    # schools table
    add_foreign_key :schools, :tournaments

    # matches table
    add_foreign_key :matches, :tournaments
    add_foreign_key :matches, :weights
    add_foreign_key :matches, :mats

    # mat_assignment_rules table
    add_foreign_key :mat_assignment_rules, :mats
    add_foreign_key :mat_assignment_rules, :tournaments

    # mats table
    add_foreign_key :mats, :tournaments
  end
end
