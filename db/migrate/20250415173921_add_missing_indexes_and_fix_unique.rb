class AddMissingIndexesAndFixUnique < ActiveRecord::Migration[7.0]
  def change
    # Add missing indexes
    add_index :tournament_delegates, :tournament_id
    add_index :tournament_delegates, :user_id

    add_index :tournament_backups, :tournament_id

    add_index :teampointadjusts, :school_id

    add_index :school_delegates, :school_id
    add_index :school_delegates, :user_id

    add_index :mat_assignment_rules, :tournament_id

  end
end
