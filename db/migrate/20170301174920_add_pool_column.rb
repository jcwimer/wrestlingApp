class AddPoolColumn < ActiveRecord::Migration
  def change
  	add_column :wrestlers, :pool, :integer
  end
end
