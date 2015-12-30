class GeneratingMatches < ActiveRecord::Migration
  def change
    add_column :tournaments, :curently_generating_matches, :integer
  end
end
