require 'rails/system_testing/base'

module Rails
  class SystemTestCase < ActiveSupport::TestCase
    include Rails.application.routes.url_helpers
    include Rails::SystemTesting::Base
  end
end
