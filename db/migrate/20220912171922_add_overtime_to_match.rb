class AddOvertimeToMatch < ActiveRecord::Migration[6.1]
  def change
    add_column :matches, :overtime_type, :string
  end
end
