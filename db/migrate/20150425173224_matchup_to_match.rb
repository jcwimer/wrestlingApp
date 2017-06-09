class MatchupToMatch < ActiveRecord::Migration[4.2]
  def change
    add_column :matches, :weight_id, :integer
    add_column :matches, :bracket_position, :string
    add_column :matches, :bracket_position_number, :integer
    rename_column :matches, :r_id, :w1
    rename_column :matches, :g_id, :w2


  end
end
