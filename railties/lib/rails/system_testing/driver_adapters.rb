module Rails
  module SystemTesting
    module DriverAdapters
      extend ActiveSupport::Autoload

      autoload :RackTestDriver
      autoload :SeleniumDriver

      class << self
        def lookup(name)
          const_get(name.to_s.camelize)
        end
      end
    end
  end
end
