class DropPoolNumber < ActiveRecord::Migration[4.2]
  def change
  	remove_column :wrestlers, :poolNumber
  end
end
