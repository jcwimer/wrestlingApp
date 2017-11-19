class AddTypeToTournament < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :type, :text
  end
end
