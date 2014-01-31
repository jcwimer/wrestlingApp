class AddSeedCriteriaToWrestler < ActiveRecord::Migration
  def change
  	add_column :wrestlers, :criteria, :string
  end
end
