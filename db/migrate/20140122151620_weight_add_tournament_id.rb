class WeightAddTournamentId < ActiveRecord::Migration
  def change
  	add_column :weights, :tournament_id, :integer
  end
end
