class CreateTeampointadjusts < ActiveRecord::Migration[4.2]
  def change
    create_table :teampointadjusts do |t|
      t.integer :points
      t.integer :wrestler_id
      t.timestamps null: false
    end
    add_index :teampointadjusts, :wrestler_id
  end
end
