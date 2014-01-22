class SchoolAddTournamentId < ActiveRecord::Migration
  def change
  	add_column :schools, :tournament_id, :integer
  end
end
