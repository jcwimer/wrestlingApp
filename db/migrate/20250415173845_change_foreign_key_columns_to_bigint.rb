class ChangeForeignKeyColumnsToBigint < ActiveRecord::Migration[7.0]
  def change
    # wrestlers table
    change_column :wrestlers, :school_id, :bigint
    change_column :wrestlers, :weight_id, :bigint

    # weights table
    change_column :weights, :tournament_id, :bigint

    # tournament_delegates table
    change_column :tournament_delegates, :tournament_id, :bigint
    change_column :tournament_delegates, :user_id, :bigint

    # tournaments table
    change_column :tournaments, :user_id, :bigint

    # tournament_backups table
    change_column :tournament_backups, :tournament_id, :bigint

    # teampointadjusts table
    change_column :teampointadjusts, :wrestler_id, :bigint
    change_column :teampointadjusts, :school_id, :bigint

    # school_delegates table
    change_column :school_delegates, :school_id, :bigint
    change_column :school_delegates, :user_id, :bigint

    # schools table
    change_column :schools, :tournament_id, :bigint

    # matches table
    change_column :matches, :tournament_id, :bigint
    change_column :matches, :weight_id, :bigint
    change_column :matches, :mat_id, :bigint

    # mat_assignment_rules table
    change_column :mat_assignment_rules, :mat_id, :bigint
    change_column :mat_assignment_rules, :tournament_id, :bigint

    # mats table
    change_column :mats, :tournament_id, :bigint
  end
end
