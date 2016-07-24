module AbstractDriver
  extend ActiveSupport::Autoload

  autoload :SeleniumDriver, 'action_dispatch/testing/system/drivers/selenium_driver'

  class << self
    def default_screen_size
      [1400, 1400]
    end
  end
end
