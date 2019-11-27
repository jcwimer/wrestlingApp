class AddOwnerToJobs < ActiveRecord::Migration[6.0]
  def change
    add_column :delayed_jobs, :job_owner_id, :integer
    add_column :delayed_jobs, :job_owner_type, :string
  end
end
