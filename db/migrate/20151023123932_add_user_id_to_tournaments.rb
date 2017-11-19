class AddUserIdToTournaments < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :user_id, :integer
    add_index :tournaments, :user_id 
  end
end
