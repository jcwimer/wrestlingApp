class RemoveDelayedJob < ActiveRecord::Migration[8.0]
  def up
    # Check if delayed_jobs table exists before trying to drop it
    if table_exists?(:delayed_jobs)
      drop_table :delayed_jobs
      puts "Dropped delayed_jobs table"
    else
      puts "delayed_jobs table doesn't exist, skipping"
    end
  end

  def down
    # Recreate delayed_jobs table if needed in the future
    create_table :delayed_jobs, force: true do |table|
      table.integer :priority, default: 0, null: false
      table.integer :attempts, default: 0, null: false
      table.text :handler, limit: 4294967295
      table.text :last_error
      table.datetime :run_at, precision: nil
      table.datetime :locked_at, precision: nil
      table.datetime :failed_at, precision: nil
      table.string :locked_by
      table.string :queue
      table.datetime :created_at, precision: nil
      table.datetime :updated_at, precision: nil
      table.integer :job_owner_id
      table.string :job_owner_type
      
      table.index [:priority, :run_at], name: "delayed_jobs_priority"
    end
  end
end
