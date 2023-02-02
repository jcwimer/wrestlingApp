class ChangeWeightToFloat < ActiveRecord::Migration[6.1]
  def change
    change_column :weights, :max, :decimal, precision: 15, scale: 1
  end
end
