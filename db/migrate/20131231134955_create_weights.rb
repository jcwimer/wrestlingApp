class CreateWeights < ActiveRecord::Migration
  def change
    create_table :weights do |t|
      t.integer :max

      t.timestamps
    end
  end
end
