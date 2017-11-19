class AddWNamesToMatch < ActiveRecord::Migration[4.2]
  def change
    add_column :matches, :w1_name, :string
    add_column :matches, :w2_name, :string
  end
end
