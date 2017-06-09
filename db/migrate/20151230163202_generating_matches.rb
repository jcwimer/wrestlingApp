class GeneratingMatches < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :curently_generating_matches, :integer
  end
end
