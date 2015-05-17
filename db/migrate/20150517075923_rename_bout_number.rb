class RenameBoutNumber < ActiveRecord::Migration
  def change
  	rename_column :matches, :boutNumber, :bout_number
  end
end
