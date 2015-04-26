class ChangeWNameToLoserName < ActiveRecord::Migration
  def change
    rename_column :matches, :w1_name, :loser1_name
    rename_column :matches, :w2_name, :loser2_name
  end
end
