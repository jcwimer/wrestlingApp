class CreateTournaments < ActiveRecord::Migration[4.2]
  def change
    create_table :tournaments do |t|
      t.string :name
      t.string :address
      t.string :director
      t.string :director_email

      t.timestamps null: true
    end
  end
end
