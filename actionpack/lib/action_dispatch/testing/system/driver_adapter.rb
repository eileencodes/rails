require 'action_dispatch/testing/system/driver_adapters'

module ActionDispatch
  module System
    module DriverAdapter
      extend ActiveSupport::Concern

      included do
        self.driver_adapter = :selenium_driver
      end

      module ClassMethods
        def driver_adapter=(driver_name_or_class)
          driver = DriverAdapters.lookup(driver_name_or_class).new
          driver.call
        end
      end
    end
  end
end
