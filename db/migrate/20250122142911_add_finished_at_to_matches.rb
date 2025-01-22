class AddFinishedAtToMatches < ActiveRecord::Migration[7.0]
  def up
    add_column :matches, :finished_at, :datetime
  end

  def down
    remove_column :matches, :finished_at
  end
end
