class CreateMatAssignmentRules < ActiveRecord::Migration[6.1]
  def up
    create_table :mat_assignment_rules do |t|
      t.integer :tournament_id, null: false, foreign_key: true
      t.integer :mat_id, null: false, foreign_key: true
      t.json :weight_classes # Removed `default: []`
      t.json :bracket_positions # Removed `default: []`
      t.json :rounds # Removed `default: []`

      t.timestamps
    end

    # Add unique index only if it does not already exist
    add_index :mat_assignment_rules, :mat_id, unique: true unless index_exists?(:mat_assignment_rules, :mat_id)
  end

  def down
    # Remove the unique index if it exists
    remove_index :mat_assignment_rules, :mat_id if index_exists?(:mat_assignment_rules, :mat_id)

    # Drop the table
    drop_table :mat_assignment_rules
  end
end
