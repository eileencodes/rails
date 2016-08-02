require 'rails/system_testing/driver_adapter'
require 'rails/system_testing/test_helper'

module Rails
  module SystemTesting
    module Base
      include DriverAdapter
      include TestHelper
    end
  end
end
