source 'https://rubygems.org'

ruby '3.2.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '8.0.2'

# Added in rails 7.1
gem 'rails-html-sanitizer'

# Asset Management: Propshaft for serving, Importmap for JavaScript
gem "propshaft"
gem "importmap-rails"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use sqlite3 as the database for Active Record
# Use sqlite3 version compatible with Rails 8
gem 'sqlite3', ">= 2.1", :group => :development

# JavaScript and CSS related gems
# Uglifier is not used with Propshaft by default
# CoffeeScript (.js.coffee) files need to be converted to .js as Propshaft doesn't compile them

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbo for modern page interactions
gem 'turbo-rails'
# Stimulus for JavaScript behaviors
gem 'stimulus-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', :group => :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring', :group => :development

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

#Installed by me
group :production do
  gem 'rails_12factor'
  gem 'mysql2'
end

gem 'solid_cache'
  
gem 'influxdb-rails'
# Authentication
# gem 'devise' # Removed - replaced with Rails built-in authentication

# Role Management
gem 'cancancan'
gem 'round_robin_tournament'
gem 'rb-readline'
# Replacing Delayed Job with Solid Queue
# gem 'delayed_job_active_record'
gem 'solid_queue'
gem 'solid_cable'
gem 'puma'
gem 'tzinfo-data'
gem 'daemons'
# Interface for viewing and managing background jobs
# gem 'delayed_job_web'
# Note: solid_queue-ui is not compatible with Rails 8.0 yet
# We'll create a custom UI or wait for compatibility updates
# gem 'solid_queue_ui', '~> 0.1.1'

group :development do
#  gem 'rubocop'
 gem 'bullet'
 gem 'brakeman'
 gem 'bundler-audit'
end

group :development, :test do
  gem 'mocha'
  # rails-controller-testing is needed for assert_template
  gem 'rails-controller-testing'
end

