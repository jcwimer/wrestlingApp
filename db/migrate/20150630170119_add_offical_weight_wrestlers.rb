class AddOfficalWeightWrestlers < ActiveRecord::Migration
  def change
    add_column :tournaments, :weigh_in_ref, :text
    add_column :wrestlers, :offical_weight, :decimal
    add_index :tournaments, :weigh_in_ref
    add_index :wrestlers, :offical_weight
  end
end
