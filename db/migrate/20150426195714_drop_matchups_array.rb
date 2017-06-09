class DropMatchupsArray < ActiveRecord::Migration[4.2]
  def change
    remove_column :tournaments, :matchups_array
  end
end
