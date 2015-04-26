class DropMatchupsArray < ActiveRecord::Migration
  def change
    remove_column :tournaments, :matchups_array
  end
end
