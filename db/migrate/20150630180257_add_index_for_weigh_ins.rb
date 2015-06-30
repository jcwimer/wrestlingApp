class AddIndexForWeighIns < ActiveRecord::Migration
  def change
    add_index :tournaments, :weigh_in_ref
    add_index :wrestlers, :offical_weight
  end
end
