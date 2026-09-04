class AddUpMatchesIndexToMatches < ActiveRecord::Migration[8.1]
  def change
    add_index :matches, [:tournament_id, :mat_id, :bout_number], name: "index_matches_on_tournament_mat_and_bout"
  end
end
