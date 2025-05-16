require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Wrestling
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    # Configure schema dumping for multiple databases
    config.active_record.schema_format = :ruby
    config.active_record.dump_schemas = :all
    
    # Fix deprecation warning for to_time in Rails 8.1
    config.active_support.to_time_preserves_timezone = :zone
    
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    # Restored custom settings from original application.rb
    
    # gzip assets
    # config.middleware.use Rack::Deflater # Temporarily commented out for debugging asset 404s
    
    config.active_job.queue_adapter = :solid_queue
    
    # Add all folders under app/services to the autoload paths
    config.autoload_paths += Dir[Rails.root.join('app', 'services', '**', '*')]
    # config.add_autoload_paths_to_load_path = false

    # Set cache format version to a value supported by Rails 8.0
    # Valid values are 7.0 or 7.1
    config.active_support.cache_format_version = 7.1
  end
end
