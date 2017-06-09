class RenameTypeToTournamentTypeForReal < ActiveRecord::Migration[4.2]
  def change
    rename_column :tournaments, :type, :tournament_type
  end
end
