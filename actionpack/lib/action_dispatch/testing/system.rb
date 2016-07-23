require 'capybara/rails'
require 'selenium-webdriver'
require 'rack/handler/puma'

module ActionDispatch
  module System
    module Runner
    end

    module Configuation
      DEFAULT_SCREEN_SIZE = [1400, 1400]

      def self.setup_driver(config, browser)
        config.register_driver browser  do |app|
          Capybara::Selenium::Driver.new(app, browser: :chrome).tap do |driver|
            driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(*DEFAULT_SCREEN_SIZE)
          end
        end
      end

      Capybara.configure do |config|
        setup_driver(config, :chrome)

        config.register_server :puma do |app, port|
          Rack::Handler::Puma.run(app, Port: port, Threads: '0:4')
        end

        config.server = :puma
        config.default_driver = (ENV["BROWSER"] || :chrome).to_sym
        config.server_port = 28100
      end
    end
  end

  class SystemTestCase < ActiveSupport::TestCase
    module Behavior
      extend ActiveSupport::Concern

      include Capybara::DSL
      include Rails.application.routes.url_helpers
    end

    include Behavior
  end
end
