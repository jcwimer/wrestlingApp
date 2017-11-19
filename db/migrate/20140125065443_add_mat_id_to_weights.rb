class AddMatIdToWeights < ActiveRecord::Migration[4.2]
  def change
  	add_column :weights, :mat_id, :integer
  end
end
