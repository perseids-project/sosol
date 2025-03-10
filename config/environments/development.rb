XSUGAR_STANDALONE_URL="http://localhost:9999/"
XSUGAR_STANDALONE_USE_PROXY="true"
EXIST_STANDALONE_URL="http://localhost:8800"
DEV_INIT_FILES = []

Sosol::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  # config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
  config.xsugar_standalone_url = XSUGAR_STANDALONE_URL
  config.xsugar_standalone_use_proxy = XSUGAR_STANDALONE_USE_PROXY
  config.dev_init_files = DEV_INIT_FILES
  
  # config/environments/development_secret.rb should set
  # RPX_API_KEY and RPX_REALM (site name) for RPX,
  # and possibly other unversioned secrets for development
  require File.join(File.dirname(__FILE__), 'development_secret')
end
