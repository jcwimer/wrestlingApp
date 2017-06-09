class AddMatchupsToTournament < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :matchups, :text
  end
end
