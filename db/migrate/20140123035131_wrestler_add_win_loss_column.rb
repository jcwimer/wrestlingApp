class WrestlerAddWinLossColumn < ActiveRecord::Migration
  def change
  	add_column :wrestlers, :season_win, :integer
  	add_column :wrestlers, :season_loss, :integer

  end
end
