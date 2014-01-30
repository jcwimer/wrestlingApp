class DropWeightMatId < ActiveRecord::Migration
  def change
  	remove_column :weights, :mat_id
  end
end
