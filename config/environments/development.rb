Cargoflux::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: ENV.fetch("ACTION_MAILER_URL_HOST", "localhost:3000") }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { :address => '127.0.0.1', :port => 1025 }

  ActionMailer::Base.default from: "info@cargoflux.com"

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Set encryption password for carrier product credentials
  ENV['CARRIER_PRODUCTS_ENCRYPTION_PASSWORD'] = "d0715da63eb74e6c18f4ecaf2faf7852e02a38a0b3ac2cc5004e83a4df2593a688addd81e91e3f434ea1153888a8409b01891af9390e0fd09ac79e1ecdf8a5f5"
end
