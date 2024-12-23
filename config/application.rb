require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Wrestling

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
	
  #gzip assets
    config.middleware.use Rack::Deflater
    
    config.active_job.queue_adapter = :delayed_job
    
    config.to_prepare do
      DeviseController.respond_to :html, :json
    end
    
    # Add all folders under app/services to the autoload paths
    config.autoload_paths += Dir[Rails.root.join('app', 'services', '**', '*')]
    # config.add_autoload_paths_to_load_path = false

    config.active_support.cache_format_version = 7.2
    config.load_defaults 7.2
  end  
end
