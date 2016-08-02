require 'rack/handler/puma'
require 'selenium-webdriver'

module Rails
  module SystemTesting
    module DriverAdapters
      class CapybaraSeleniumDriver
        def initialize(browser: :chrome, server: :puma, port: 28100, screen_size: [1400,1400])
          @browser = browser
          @server  = server
          @port    = port
          @screen_size = screen_size
        end

        def call
          registration
          setup
        end

        def registration
          register_driver
          register_server
        end

        def setup
          set_server
          set_driver
          set_port
        end

        def register_driver
          Capybara.register_driver @browser do |app|
            Capybara::Selenium::Driver.new(app, browser: @browser).tap do |driver|
              driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(*@screen_size)
            end
          end
        end

        def register_server
          Capybara.register_server @server do |app, port|
            ::Rack::Handler::Puma.run(app, Port: port, Threads: '0:4')
          end
        end

        def set_server
          Capybara.server = @server
        end

        def set_driver
          Capybara.default_driver = @browser.to_sym
        end

        def set_port
          Capybara.server_port = @port
        end
      end
    end
  end
end
