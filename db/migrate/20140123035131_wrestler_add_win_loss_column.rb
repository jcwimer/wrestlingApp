class WrestlerAddWinLossColumn < ActiveRecord::Migration[4.2]
  def change
  	add_column :wrestlers, :season_win, :integer
  	add_column :wrestlers, :season_loss, :integer

  end
end
