require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # This is needed to prevent origin errors in login
  config.assume_ssl = ENV["REVERSE_PROXY_SSL_TERMINATION"] == "true"

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # Force SSL in production when RAILS_SSL_TERMINATION is true
  config.force_ssl = ENV["RAILS_SSL_TERMINATION"] == "true"

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # Using Solid Cache with MySQL
  config.cache_store = :solid_cache_store
  # Don't use connects_to here since it's configured via cache.yml
  # config.solid_cache.connects_to = { database: { writing: :cache } }

  # Configure path for cache migrations
  config.paths["db/migrate"] << "db/cache/migrate"

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  # Don't use connects_to here since it's configured via queue.yml
  # config.solid_queue.connects_to = { database: { writing: :queue } }
  
  # Configure path for queue migrations
  config.paths["db/migrate"] << "db/queue/migrate"
  
  # Configure ActionCable to use its own database
  # Don't use connects_to here since it's configured via cable.yml
  # config.action_cable.connects_to = { database: { writing: :cable } }
  
  # Configure path for cable migrations
  config.paths["db/migrate"] << "db/cable/migrate"

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "wrestlingdev.com" }

  # Restore custom SMTP settings
  config.action_mailer.smtp_settings = {
    :address              => "smtp.gmail.com",
    :port                 => 587,
    :domain               => "gmail.com",
    :user_name            => ENV["WRESTLINGDEV_EMAIL"],
    :password             => ENV["WRESTLINGDEV_EMAIL_PWD"],
    :authentication       => :plain,
    :enable_starttls_auto => true
  }
  config.action_mailer.perform_deliveries = true
  # Login needs origin of email
  Rails.application.routes.default_url_options[:host] = 'https://wrestlingdev.com'

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  
  # Restore asset compilation settings
  config.public_file_server.enabled = true
  
  ## Using default asset pipeline sprockets
  #Live compile with sprockets instead of: rails assets:precompile
  config.assets.compile = true
  # Generate digests for assets URLs.
  config.assets.digest = true
end
