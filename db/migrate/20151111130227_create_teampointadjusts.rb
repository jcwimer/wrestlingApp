class CreateTeampointadjusts < ActiveRecord::Migration
  def change
    create_table :teampointadjusts do |t|
      t.integer :points
      t.integer :wrestler_id
      t.timestamps null: false
    end
    add_index :teampointadjusts, :wrestler_id
  end
end
