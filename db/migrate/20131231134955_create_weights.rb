class CreateWeights < ActiveRecord::Migration[4.2]
  def change
    create_table :weights do |t|
      t.integer :max

      t.timestamps null: true
    end
  end
end
