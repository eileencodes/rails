require 'capybara/rails'
require 'rack/handler/puma'
require 'rails/system/abstract_driver'

module Rails
  module System
    include AbstractDriver::SeleniumDriver
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
