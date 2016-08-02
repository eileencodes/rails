require 'capybara/rails'

module Rails
  module SystemTesting
    module TestHelper
      include Capybara::DSL

      def after_teardown
        Capybara.reset_sessions!
        super
      end
    end
  end
end
