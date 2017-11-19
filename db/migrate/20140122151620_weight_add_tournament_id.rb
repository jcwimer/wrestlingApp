class WeightAddTournamentId < ActiveRecord::Migration[4.2]
  def change
  	add_column :weights, :tournament_id, :integer
  end
end
