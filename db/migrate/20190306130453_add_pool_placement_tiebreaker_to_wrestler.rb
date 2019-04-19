class AddPoolPlacementTiebreakerToWrestler < ActiveRecord::Migration[5.2]
  def change
  	add_column :wrestlers, :pool_placement_tiebreaker, :string
  end
end
