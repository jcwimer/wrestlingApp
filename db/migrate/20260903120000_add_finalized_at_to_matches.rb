class AddFinalizedAtToMatches < ActiveRecord::Migration[8.1]
  def up
    add_column :matches, :finalized_at, :datetime
    execute <<~SQL.squish
      UPDATE matches
      SET finalized_at = COALESCE(finished_at, updated_at)
      WHERE finished = 1
    SQL
  end

  def down
    remove_column :matches, :finalized_at
  end
end
