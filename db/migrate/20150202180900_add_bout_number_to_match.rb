class AddBoutNumberToMatch < ActiveRecord::Migration[4.2]
  def change
  	add_column :matches, :boutNumber, :integer
  end
end
