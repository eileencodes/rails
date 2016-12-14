require "abstract_unit"
require "active_job"

class ActiveJobSetupTest < ActiveSupport::TestCase
  setup do
    @test_session = RailsApp
    ActiveJob::Base.queue_adapter = :inline
  end

  def test_set_queue_adapter_to_async
    @test_session.set_queue_adapter_to_async

    assert_kind_of ActiveJob::QueueAdapters::AsyncAdapter, ActiveJob::Base.queue_adapter
  end

  def test_reset_queue_adapter_to_original
    @test_session.set_queue_adapter_to_async
    @test_session.reset_queue_adapter_to_original

    assert_kind_of ActiveJob::QueueAdapters::InlineAdapter, ActiveJob::Base.queue_adapter
  end
end
