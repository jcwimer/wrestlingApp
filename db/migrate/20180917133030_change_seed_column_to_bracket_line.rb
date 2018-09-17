class ChangeSeedColumnToBracketLine < ActiveRecord::Migration[5.2]
  def change
  	rename_column :wrestlers, :seed, :bracket_line
  end
end
