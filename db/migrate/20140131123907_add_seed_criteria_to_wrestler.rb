class AddSeedCriteriaToWrestler < ActiveRecord::Migration[4.2]
  def change
  	add_column :wrestlers, :criteria, :string
  end
end
