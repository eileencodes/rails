require "action_system_test/test_helpers"

module ActionSystemTest
  module TestHelper # :nodoc:
    include TestHelpers::ActiveJobSetup
    include TestHelpers::ScreenshotHelper
  end
end
