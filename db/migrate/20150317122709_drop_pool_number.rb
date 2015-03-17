class DropPoolNumber < ActiveRecord::Migration
  def change
  	remove_column :wrestlers, :poolNumber
  end
end
