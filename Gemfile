source 'https://rubygems.org'

ruby '3.2.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '7.2.2'

# Added in rails 7.1
gem 'rails-html-sanitizer'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use sqlite3 as the database for Active Record
# can't use 2.0 maybe in a future rails upgrade?
gem 'sqlite3', "~> 1.4", :group => :development

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', :group => :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring', :group => :development

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

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
  gem 'dalli'
end

gem 'influxdb-rails'
gem 'devise'
gem 'cancancan'
gem 'round_robin_tournament'
gem 'rb-readline'
gem 'delayed_job_active_record'
gem 'puma'
gem 'passenger'
gem 'tzinfo-data'
gem 'daemons'
gem 'delayed_job_web'

group :development do
#  gem 'rubocop'
 gem 'bullet'
 gem 'brakeman'
 gem 'bundler-audit'
end

