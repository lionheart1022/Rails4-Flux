require "custom_ssl_middleware"

Cargoflux::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.serve_static_files = false
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.assets.digest = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  config.middleware.swap ::ActionDispatch::SSL, CustomSSLMiddleware, config.ssl_options

  config.log_level = :info

  config.log_tags = [ :uuid ]

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # mail
  config.action_mailer.default_url_options = { :host => "app.cargoflux.com", :protocol => "http://" }
  config.action_mailer.raise_delivery_errors = true
  ActionMailer::Base.smtp_settings = {
      :address => 'smtp.sendgrid.net',
      :port => '587',
      :authentication => :plain,
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :domain => 'cargoflux.com',
      :enable_starttls_auto => true
  }
  ActionMailer::Base.default :from => 'info@cargoflux.com'
end
