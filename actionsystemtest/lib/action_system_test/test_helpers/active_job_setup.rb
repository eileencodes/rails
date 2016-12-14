module ActionSystemTest
  module TestHelpers
    # Active Job setup helper for system testing
    module ActiveJobSetup
      # Sets the queue adapter to async and remembers the original adapter
      # setting.
      #
      # This method should be used in the test setup code so that jobs run
      # when the test runs because the test can't wait to check for pass/fail
      # if it depends on running jobs.
      def set_queue_adapter_to_async
        @original_queue_adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new
      end

      # Sets the queue adapter back to the original adapter.
      #
      # This method should be used in the test teardown code so that the
      # queue adapter is always set back to the original queue adapter.
      def reset_queue_adapter_to_original
        ActiveJob::Base.queue_adapter = @original_queue_adapter
      end
    end
  end
end
