class AddExtraFlagForWrestler < ActiveRecord::Migration[4.2]
  def change
  	add_column :wrestlers, :extra, :boolean
  end
end
