class AddFinishedFieldToMatches < ActiveRecord::Migration
  def change
  	add_column :matches, :finished, :integer
  end
end
