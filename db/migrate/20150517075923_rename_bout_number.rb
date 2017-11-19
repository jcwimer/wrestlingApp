class RenameBoutNumber < ActiveRecord::Migration[4.2]
  def change
  	rename_column :matches, :boutNumber, :bout_number
  end
end
