class CreateMats < ActiveRecord::Migration[4.2]
  def change
    create_table :mats do |t|
      t.string :name
      t.integer :tournament_id

      t.timestamps null: true
    end
  end
end
