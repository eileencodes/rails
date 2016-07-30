module ActionDispatch
  module System
    module DriverAdapters
      extend ActiveSupport::Autoload

      autoload :RackTestDriver, 'action_dispatch/testing/system/driver_adapters/rack_test_driver'
      autoload :SeleniumDriver, 'action_dispatch/testing/system/driver_adapters/selenium_driver'

      class << self
        def lookup(name)
          const_get(name.to_s.camelize)
        end
      end
    end
  end
end
