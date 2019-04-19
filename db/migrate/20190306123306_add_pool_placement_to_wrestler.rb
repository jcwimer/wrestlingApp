class AddPoolPlacementToWrestler < ActiveRecord::Migration[5.2]
  def change
  	add_column :wrestlers, :pool_placement, :integer
  end
end
