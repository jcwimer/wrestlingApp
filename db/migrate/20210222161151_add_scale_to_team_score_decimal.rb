class AddScaleToTeamScoreDecimal < ActiveRecord::Migration[6.1]
  def change
    change_column :schools, :score, :decimal, precision: 15, scale: 1
  end
end
