source 'https://rubygems.org'
ruby '2.3.7'

gem 'puma', '~> 3.12.0'
gem 'rails', '~> 4.2.0'
gem 'pg', '~> 0.20.0'

# A gem that provides a client interface for the Sentry error logger
gem 'sentry-raven', '~> 2.7.0'

# ActiveRecord backend for Delayed::Job
gem 'delayed_job_active_record', '~> 4.1.0'

# Clientside localtime
gem 'local_time', '~> 2.1.0'

# Users
gem "devise", ">= 4.7.1"

# Countries
gem 'countries', '~> 2.0.0', require: 'countries/global'

# Form generation
gem 'simple_form', '~> 3.1.0'
gem 'country_select', '~> 1.2.0'

# Haml (HTML Abstraction Markup Language) is a layer on top of HTML or XML
gem 'haml', '~> 5.0.0'
gem 'haml-rails', '~> 1.0.0'

# lodash
gem 'lodash-rails'

# File attachments
gem 'aws-sdk', '~> 1.54.0'
gem 'paperclip', '< 5' # Paperclip v5+ drops support for AWS v1
gem 's3_direct_upload', '~> 0.1.6'

# Currency data
gem 'money', '~> 6.7.0'

# Pagination
gem 'kaminari', '~> 1.0'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 2.7.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# Integrate React.js with Rails views and controllers, the asset pipeline, or webpacker
gem 'react-rails', '~> 2.4.0'

# HTTP / XML
gem 'faraday', '~> 0.8.8'
gem 'faraday_middleware', '~> 0.10.0'
gem "nokogiri", ">= 1.10.4"

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.3.0'
gem 'jquery-ui-rails', '~> 6.0.0'

gem 'select2-rails', '~> 4.0'
gem 'rails-assets-moment', '2.14.1', source: 'https://rails-assets.org'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# Encryption for saving autobook credentials
gem 'aescrypt', '~> 1.0.0'

# SFTP
gem 'net-sftp', '~> 2.1.2'

# PDF
gem 'prawn', '~> 2.2.0' # Prawn is a fast, tiny, and nimble PDF generator for Ruby
gem 'barby', '~> 0.6.0' # Barby creates barcodes

# Excel
gem 'write_xlsx', '~> 0.77.0' # for writing excel files
gem 'creek', '~> 1.0.5' # alternative excel parser

gem 'rubyzip', '1.2.2' # rubyzip is a ruby module for reading and writing zip files

# ImageMagick
gem 'mini_magick', '~> 4.9.4' # Manipulate images with minimal use of memory via ImageMagick / GraphicsMagick

# respond_with / respond_to
gem 'responders', '~> 2.0'

gem 'scientist', '~> 1.2.0' # A Ruby library for carefully refactoring critical paths

group :development, :test do
  gem 'minitest-rails', '< 3' # v3+ requires Rails 5
  gem 'minitest-focus', '~> 1.1.0'
  gem 'factory_bot_rails', '~> 4.11.0'
  gem 'spring'
  gem 'byebug'
  gem 'faker'
end

group :development do
  gem 'web-console', '< 3.3.1' # v3.3.1 drops support for Rails 4.2.
  gem 'quiet_assets', '~> 1.1.0'
end

# Heroku specific - see https://devcenter.heroku.com/articles/getting-started-with-rails4
group :production, :staging do
  gem 'rails_12factor'
end
