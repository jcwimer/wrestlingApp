class DropWeightMatId < ActiveRecord::Migration[4.2]
  def change
  	remove_column :weights, :mat_id
  end
end
