class AddOfficalWeightWrestlers < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :weigh_in_ref, :text
    add_column :wrestlers, :offical_weight, :decimal
  end
end
