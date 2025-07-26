require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Chillonrails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    
    config.exceptions_app = self.routes

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    config.action_mailer.delivery_method = :postmark
    config.action_mailer.postmark_settings = { :api_token => "6ee07d77-a4b7-4214-8d32-c221dc379343" }

    # Don't generate system test files.
    config.generators do |g|
      g.test_framework :rspec,                # Set RSpec as the test framework
                        fixtures: true,       # Generate fixtures (or factories)
                        view_specs: false,    # Generate view specs
                        helper_specs: false,  # Don't generate helper specs
                        routing_specs: false, # Generate routing specs
                        request_specs: true,  # Generate request specs
                        system_tests: nil     # Disable system test generation inside this block

      # Use FactoryBot for generating test data
      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.helper false                         # Disable helper generation
    end

  end
end
