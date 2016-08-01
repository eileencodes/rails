module Rails
  module SystemTesting
    module DriverAdapters
      class RackTestDriver
        def call
          registration
        end

        def registration
          Capybara.register_driver :rack_test do |app|
            Capybara::RackTest::Driver.new(app, headers: { 'HTTP_USER_AGENT' => 'Capybara' })
          end
        end
      end
    end
  end
end
