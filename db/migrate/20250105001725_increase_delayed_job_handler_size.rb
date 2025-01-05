class IncreaseDelayedJobHandlerSize < ActiveRecord::Migration[7.2]
  def change
    change_column :delayed_jobs, :handler, :text, limit: 4294967295 # Change to LONGTEXT
  end
end
