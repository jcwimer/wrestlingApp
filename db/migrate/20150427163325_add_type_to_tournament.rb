class AddTypeToTournament < ActiveRecord::Migration
  def change
    add_column :tournaments, :type, :text
  end
end
