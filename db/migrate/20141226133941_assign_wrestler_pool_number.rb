class AssignWrestlerPoolNumber < ActiveRecord::Migration[4.2]
  def change
	  add_column :wrestlers, :poolNumber, :integer
  end
end
