require 'selenium-webdriver'

module AbstractDriver
  module SeleniumDriver
    module Configuation
      # setup a default - rack - and then make it configurable
      # within a config setting. So the config setting would setu
      # the browser default, server, and driver
      Capybara.register_driver :chrome do |app|
        Capybara::Selenium::Driver.new(app, browser: :chrome).tap do |driver|
          driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(*AbstractDriver.default_screen_size)
        end
      end

      Capybara.register_server :puma do |app, port|
        Rack::Handler::Puma.run(app, Port: port, Threads: '0:4')
      end

      Capybara.server = :puma
      Capybara.default_driver = (ENV["BROWSER"] || :chrome).to_sym
      # might not be necessary
      Capybara.server_port = 28100
    end
  end
end
