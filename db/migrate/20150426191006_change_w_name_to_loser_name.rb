class ChangeWNameToLoserName < ActiveRecord::Migration[4.2]
  def change
    rename_column :matches, :w1_name, :loser1_name
    rename_column :matches, :w2_name, :loser2_name
  end
end
