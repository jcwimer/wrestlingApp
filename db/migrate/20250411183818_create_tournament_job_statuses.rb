class CreateTournamentJobStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :tournament_job_statuses do |t|
      t.bigint :tournament_id, null: false
      t.string :job_name, null: false
      t.string :status, null: false, default: "Queued"  # Queued, Running, Errored
      t.text :details  # Additional details about the job (e.g., wrestler name, school name)
      t.timestamps
    end
    
    add_index :tournament_job_statuses, :tournament_id
    add_index :tournament_job_statuses, [:tournament_id, :job_name]
    add_foreign_key :tournament_job_statuses, :tournaments
  end
end
