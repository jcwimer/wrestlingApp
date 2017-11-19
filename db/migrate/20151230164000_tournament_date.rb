class TournamentDate < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :date, :date
  end
end
