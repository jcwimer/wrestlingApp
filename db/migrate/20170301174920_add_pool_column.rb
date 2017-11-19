class AddPoolColumn < ActiveRecord::Migration[4.2]
  def change
  	add_column :wrestlers, :pool, :integer
  end
end
