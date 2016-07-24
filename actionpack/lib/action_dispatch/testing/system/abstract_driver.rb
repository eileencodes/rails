module AbstractDriver
  extend ActiveSupport::Autoload

  autoload :RackTestDriver, 'action_dispatch/testing/system/drivers/rack_test_driver'
  autoload :SeleniumDriver, 'action_dispatch/testing/system/drivers/selenium_driver'

  class << self
    def default_screen_size
      [1400, 1400]
    end
  end
end
