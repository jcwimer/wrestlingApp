class AddFinishedFieldToMatches < ActiveRecord::Migration[4.2]
  def change
  	add_column :matches, :finished, :integer
  end
end
