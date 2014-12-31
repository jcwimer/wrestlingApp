class AssignWrestlerPoolNumber < ActiveRecord::Migration
  def change
	  add_column :wrestlers, :poolNumber, :integer
  end
end
