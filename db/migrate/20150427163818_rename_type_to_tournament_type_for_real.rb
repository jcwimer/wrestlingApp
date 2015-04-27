class RenameTypeToTournamentTypeForReal < ActiveRecord::Migration
  def change
    rename_column :tournaments, :type, :tournament_type
  end
end
