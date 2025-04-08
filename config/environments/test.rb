# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with cache-control for performance.
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }

  # Show full error reports.
  config.consider_all_requests_local = true
  
  # Use solid cache store for testing
  config.cache_store = :solid_cache_store
  # Don't use connects_to here since it's configured via cache.yml
  # config.solid_cache.connects_to = { database: { writing: :cache } }

  # Configure path for cache migrations
  config.paths["db/migrate"] << "db/cache/migrate"

  # Configure ActiveJob to execute jobs immediately in tests
  # The test adapter will execute jobs inline immediately
  config.active_job.queue_adapter = :test
  
  # Configure path for queue migrations  
  config.paths["db/migrate"] << "db/queue/migrate"
  
  # Configure ActionCable to use its own database for testing
  # Don't use connects_to here since it's configured via cable.yml
  # config.action_cable.connects_to = { database: { writing: :cable } }
  
  # Configure path for cable migrations
  config.paths["db/migrate"] << "db/cable/migrate"

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "example.com" }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Set test order to random as in previous configuration
  config.active_support.test_order = :random

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true
end
