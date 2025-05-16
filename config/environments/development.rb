require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # allow all hostnames
  config.hosts.clear

  # Make code changes take effect immediately without server restart.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing.
  config.server_timing = true

  # Enable/disable Action Controller caching. By default Action Controller caching is disabled.
  # Run rails dev:cache to toggle Action Controller caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
  end

  # Replace the default in-process memory cache store with a durable alternative.
  # Using Solid Cache with MySQL
  config.cache_store = :solid_cache_store
  # Don't use connects_to here since it's configured via cache.yml
  # config.solid_cache.connects_to = { database: { writing: :cache } }

  # Configure Solid Queue as the ActiveJob queue adapter
  config.active_job.queue_adapter = :solid_queue
  # Don't use connects_to here since it's configured via queue.yml
  # config.solid_queue.connects_to = { database: { writing: :queue } }
  config.solid_queue.connects_to = { database: { writing: :queue, reading: :queue } }
  
  # Configure ActionCable to use its own database
  # Don't use connects_to here since it's configured via cable.yml
  # config.action_cable.connects_to = { database: { writing: :cable } }
  
  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Make template changes take effect immediately.
  config.action_mailer.perform_caching = false

  # Set localhost to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Append comments with runtime information tags to SQL queries in logs.
  config.active_record.query_log_tags_enabled = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true
  
  # Restore Bullet configuration
  config.after_initialize do
    #Bullet.enable = true
    #Bullet.alert = true
    #Bullet.console = true
    #Bullet.bullet_logger = true
  end

  # Raise error on unpermitted parameters, because we want to be sure we're catching them all.
  config.action_controller.action_on_unpermitted_parameters = :raise

  # Dump the schema after migrations
  config.active_record.dump_schema_after_migration = true

 # Nobuild in development
 config.assets.build_assets = false
end
