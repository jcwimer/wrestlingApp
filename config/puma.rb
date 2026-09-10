# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.
#
# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# You can control the number of workers using ENV["WEB_CONCURRENCY"]. You
# should only set this value when you want to run 2 or more workers. The
# default is already 1.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The Compose deployments use five threads per worker to balance throughput,
# latency, and the default production database connection pool.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.

workers_count = ENV.fetch("WEB_CONCURRENCY", ENV["RAILS_ENV"] == "production" ? 2 : 1).to_i
workers workers_count if workers_count > 1

max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count).to_i
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments
# Enable by default in development for convenience, can be disabled with SOLID_QUEUE_IN_PUMA=false
if (Rails.env.development? && ENV["SOLID_QUEUE_IN_PUMA"] != "false") || ENV["SOLID_QUEUE_IN_PUMA"] == "true"
  plugin :solid_queue
end

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# Set reasonable timeouts - these prevent hanging requests from consuming resources
worker_timeout 60
worker_boot_timeout 60

# Preload the application to reduce memory footprint in production
preload_app! if ENV["RAILS_ENV"] == "production"

# When using preload_app, disconnect inherited connections so each worker opens its own.
before_worker_boot do
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection_handler.connection_pool_list.each(&:disconnect!)
  end
end

# Log the configuration
puts "Puma starting with #{workers_count} worker(s), #{min_threads_count}-#{max_threads_count} threads per worker"
