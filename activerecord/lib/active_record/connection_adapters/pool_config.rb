# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    class PoolConfig # :nodoc:
      include Mutex_m

      attr_reader :db_config, :connection_specification_name, :schema_cache

      INSTANCES = ObjectSpace::WeakMap.new
      private_constant :INSTANCES

      class << self
        def discard_pools!
          INSTANCES.each_key(&:discard_pool!)
        end
      end

      def initialize(connection_specification_name, db_config)
        super()
        @connection_specification_name = connection_specification_name
        @db_config = db_config
        @pool = nil
        @schema_cache = setup_schema_cache
        INSTANCES[self] = self
      end

      def disconnect!
        ActiveSupport::ForkTracker.check!

        return unless @pool

        synchronize do
          return unless @pool

          @pool.automatic_reconnect = false
          @pool.disconnect!
        end

        nil
      end

      def setup_schema_cache
        path = db_config.schema_cache_path
        filename = ActiveRecord::Tasks::DatabaseTasks.cache_dump_filename(db_config.spec_name, schema_cache_path: path)
        p filename
        ActiveRecord::ConnectionAdapters::SchemaCache.load_from(filename)
      end

      def pool
        ActiveSupport::ForkTracker.check!

        @pool || synchronize { @pool ||= ConnectionAdapters::ConnectionPool.new(self) }
      end

      def discard_pool!
        return unless @pool

        synchronize do
          return unless @pool

          @pool.discard!
          @pool = nil
        end
      end
    end
  end
end

ActiveSupport::ForkTracker.after_fork { ActiveRecord::ConnectionAdapters::PoolConfig.discard_pools! }
