class AddIsPublicToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :is_public, :boolean
  end
end
