class CreateSchools < ActiveRecord::Migration[4.2][4.2]
  def change
    create_table :schools do |t|
      t.string :name
      t.integer :score

      t.timestamps null: true
    end
  end
end
