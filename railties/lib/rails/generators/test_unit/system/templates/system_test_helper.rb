require 'test_helper'

class ActionSystemTestCase < ActionSystemTest::Base
  setup do
    set_queue_adapter_to_async
  end

  teardown do
    take_failed_screenshot
    reset_queue_adapter_to_original
    Capybara.reset_sessions!
  end
end
