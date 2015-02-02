class AddBoutNumberToMatch < ActiveRecord::Migration
  def change
  	add_column :matches, :boutNumber, :integer
  end
end
