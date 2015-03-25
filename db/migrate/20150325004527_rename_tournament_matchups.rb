class RenameTournamentMatchups < ActiveRecord::Migration
  def change
    rename_column :tournaments, :matchups, :matchups_array
  end
end
