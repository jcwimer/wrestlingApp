class CreateMats < ActiveRecord::Migration
  def change
    create_table :mats do |t|
      t.string :name
      t.integer :tournament_id

      t.timestamps
    end
  end
end
