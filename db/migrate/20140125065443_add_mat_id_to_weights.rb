class AddMatIdToWeights < ActiveRecord::Migration
  def change
  	add_column :weights, :mat_id, :integer
  end
end
