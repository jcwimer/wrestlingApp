class CreateTournamentBackups < ActiveRecord::Migration[7.0]
  def up
    create_table :tournament_backups do |t|
      t.integer :tournament_id, null: false, foreign_key: true
      t.text :backup_data, null: false, limit: 4294967295 # Use LONGTEXT for large backups
      t.string :backup_reason
      t.timestamps
    end
  end

  def down
    # Drop the table
    drop_table :tournament_backups
  end
end

