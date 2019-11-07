require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Cargoflux
  class Application < Rails::Application
    config.autoload_paths += Dir["#{config.root}/app/models/errors"]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**/}')]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', 'dhl_sub')]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', 'send24')]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', 'unifaun')]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', 'gtx')]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', 'geodis')]
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    config.to_prepare do
      Devise::SessionsController.layout "application"
      Devise::ConfirmationsController.layout "devise"
      Devise::UnlocksController.layout "devise"
      Devise::PasswordsController.layout "devise"
    end

    config.active_record.raise_in_transactional_callbacks = true

    config.active_job.queue_adapter = :delayed_job

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "Copenhagen"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
  end
end
