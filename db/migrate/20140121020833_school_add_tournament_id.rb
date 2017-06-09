class SchoolAddTournamentId < ActiveRecord::Migration[4.2]
  def change
  	add_column :schools, :tournament_id, :integer
  end
end
