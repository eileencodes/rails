module ActionSystemTest
  module TestHelpers
    module ActiveJobSetup
      def set_queue_adapter_to_async
        @original_queue_adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new
      end

      def reset_queue_adapter_to_original
        ActiveJob::Base.queue_adapter = @original_queue_adapter
      end
    end
  end
end
