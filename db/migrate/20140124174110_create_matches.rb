class CreateMatches < ActiveRecord::Migration[4.2]
  def change
    create_table :matches do |t|
      t.integer :r_id
      t.integer :g_id
      t.text :g_stat
      t.text :r_stat
      t.integer :winner_id
      t.string :win_type
      t.string :score

      t.timestamps null: true
    end
  end
end
