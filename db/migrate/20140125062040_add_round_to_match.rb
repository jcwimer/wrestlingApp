class AddRoundToMatch < ActiveRecord::Migration[4.2]
  def change
  	add_column :matches, :round, :integer
  end
end
