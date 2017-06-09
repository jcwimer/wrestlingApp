class AddMatIdToMatch < ActiveRecord::Migration[4.2]
  def change
    add_column :matches, :mat_id, :integer
    add_index :matches, :mat_id
  end
end
