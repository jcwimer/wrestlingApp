class RenameStats < ActiveRecord::Migration
  def change
    rename_column :matches, :g_stat, :w1_stat
    rename_column :matches, :r_stat, :w2_stat
  end
end
