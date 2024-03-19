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
    
    config.autoload_paths << "#{config.root}/app/services/tournament_services"
    config.autoload_paths << "#{config.root}/app/services/wrestler_services"
    config.autoload_paths << "#{config.root}/app/services/weight_services"
    config.autoload_paths << "#{config.root}/app/services/bracket_advancement"
    config.autoload_paths << "#{config.root}/app/services/school_services"
    config.add_autoload_paths_to_load_path = false

    config.active_support.cache_format_version = 7.1
    config.load_defaults 7.1
  end  
end
