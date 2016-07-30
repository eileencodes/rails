require 'capybara/rails'
require 'rack/handler/puma'
require 'action_dispatch/testing/system/driver_adapter'

module ActionDispatch
  module System
    include DriverAdapter
  end

  class SystemTestCase < ActiveSupport::TestCase
    module Behavior
      extend ActiveSupport::Concern

      include Capybara::DSL
      include Rails.application.routes.url_helpers

      def before_setup
        super
      end

      def after_teardown
        Capybara.reset_sessions!
        super
      end
    end

    include Behavior
  end
end
