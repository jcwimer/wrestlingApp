class CreateTournamentDelegates < ActiveRecord::Migration[4.2]
  def change
    create_table :tournament_delegates do |t|
      t.integer :user_id
      t.integer :tournament_id

      t.timestamps null: false
    end
  end
end
