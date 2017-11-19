class AddTournamentIdToMatches < ActiveRecord::Migration[4.2]
  def change
  	add_column :matches, :tournament_id, :integer
  end
end
