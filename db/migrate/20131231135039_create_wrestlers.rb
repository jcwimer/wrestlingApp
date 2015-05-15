class CreateWrestlers < ActiveRecord::Migration
  def change
    create_table :wrestlers do |t|
      t.string :name
      t.integer :school_id
      t.integer :weight_id
      t.integer :seed
      t.integer :original_seed

      t.timestamps null: true
    end
  end
end
