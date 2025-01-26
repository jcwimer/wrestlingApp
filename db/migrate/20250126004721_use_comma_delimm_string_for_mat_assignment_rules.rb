class UseCommaDelimmStringForMatAssignmentRules < ActiveRecord::Migration[7.2]
  def change
    change_column :mat_assignment_rules, :weight_classes, :string
    change_column :mat_assignment_rules, :bracket_positions, :string
    change_column :mat_assignment_rules, :rounds, :string
  end
end
