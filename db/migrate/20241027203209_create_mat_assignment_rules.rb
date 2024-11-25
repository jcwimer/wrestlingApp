class CreateMatAssignmentRules < ActiveRecord::Migration[6.1]
  def up
    create_table :mat_assignment_rules do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :mat, null: false, foreign_key: true
      t.json :weight_classes, default: []
      t.json :bracket_positions, default: []
      t.json :rounds, default: []

      t.timestamps
    end

    # Add unique index on mat_id if it does not already exist
    add_index :mat_assignment_rules, :mat_id, unique: true unless index_exists?(:mat_assignment_rules, :mat_id)
    
    # Add index on tournament_id for faster lookups
    add_index :mat_assignment_rules, :tournament_id unless index_exists?(:mat_assignment_rules, :tournament_id)
  end

  def down
    # Remove indexes if they exist
    remove_index :mat_assignment_rules, :mat_id if index_exists?(:mat_assignment_rules, :mat_id)
    remove_index :mat_assignment_rules, :tournament_id if index_exists?(:mat_assignment_rules, :tournament_id)

    # Drop the table
    drop_table :mat_assignment_rules
  end
end
