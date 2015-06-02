class AddPoolNumberToWrestlers < ActiveRecord::Migration
  def change
    add_column :wrestlers, :pool_number, :integer
  end
end
