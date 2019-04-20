class IncreaseDelayedJobsHandler < ActiveRecord::Migration[5.2]
  def change
  	# 4294967295 is the maximum longtext size for mysql
  	# change_column :delayed_jobs, :handler, :text, :limit => 4294967295
  	change_column :delayed_jobs, :handler, :longtext
  end
end
