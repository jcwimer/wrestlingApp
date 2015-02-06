class AddExtraFlagForWrestler < ActiveRecord::Migration
  def change
  	add_column :wrestlers, :extra, :boolean
  end
end
