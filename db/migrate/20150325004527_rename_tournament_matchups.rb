class RenameTournamentMatchups < ActiveRecord::Migration[4.2]
  def change
    rename_column :tournaments, :matchups, :matchups_array
  end
end
