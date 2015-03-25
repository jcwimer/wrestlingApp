class AddMatchupsToTournament < ActiveRecord::Migration
  def change
    add_column :tournaments, :matchups, :text
  end
end
