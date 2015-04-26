class AddWNamesToMatch < ActiveRecord::Migration
  def change
    add_column :matches, :w1_name, :string
    add_column :matches, :w2_name, :string
  end
end
