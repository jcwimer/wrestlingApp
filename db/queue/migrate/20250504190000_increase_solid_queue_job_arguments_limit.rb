class IncreaseSolidQueueJobArgumentsLimit < ActiveRecord::Migration[8.0]
  def up
    # Allow large payloads (e.g., pasted import text) to be enqueued without blowing up MySQL's TEXT limit (~64KB).
    change_column :solid_queue_jobs, :arguments, :text, limit: 16.megabytes - 1
  end

  def down
    change_column :solid_queue_jobs, :arguments, :text
  end
end
