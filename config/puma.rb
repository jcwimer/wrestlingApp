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
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.

# Calculate available memory for Ruby process sizing (in MB)
available_memory_mb = if RUBY_PLATFORM =~ /darwin/
  # Default to a reasonable amount on macOS where memory detection is difficult
  8192 # 8GB default
else
  begin
    # Try to get memory from /proc/meminfo on Linux
    mem_total_kb = `grep MemTotal /proc/meminfo`.to_s.strip.split(/\s+/)[1].to_i
    mem_total_mb = mem_total_kb / 1024
    # If we couldn't detect memory, use a safe default
    mem_total_mb > 0 ? mem_total_mb : 4096
  rescue
    4096 # 4GB fallback if detection fails
  end
end

# Calculate workers based on available CPUs and memory
# Each worker uses ~300-500MB of RAM, so we scale based on available memory
# If WEB_CONCURRENCY is set, use that value instead
cpu_count = begin
  require 'etc'
  Etc.nprocessors
rescue
  2 # Default to 2 if we can't detect
end

# Default worker calculation:
# - With ample memory: Use CPU count
# - With limited memory: Use memory-based calculation with a min of 2 and max based on CPUs
# This automatically adapts to the environment
default_workers = if ENV["RAILS_ENV"] == "development"
  1 # Use 1 worker in development for simplicity
else
  # Calculate based on available memory, assuming ~400MB per worker
  memory_based_workers = (available_memory_mb / 400).to_i
  # Ensure at least 2 workers for production (for zero-downtime restarts)
  # and cap at CPU count to avoid excessive context switching
  [memory_based_workers, 2].max
end
default_workers = [default_workers, cpu_count].min

workers_count = ENV.fetch("WEB_CONCURRENCY") { default_workers }

# Configure thread count for optimal throughput
# More threads = better for IO-bound applications
# Fewer threads = better for CPU-bound applications
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", 5)
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 12)
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

# When using preload_app, ensure that connections are properly handled
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Log the configuration
puts "Puma starting with #{workers_count} worker(s), #{min_threads_count}-#{max_threads_count} threads per worker"
puts "Available system resources: #{cpu_count} CPU(s), #{available_memory_mb}MB RAM"
