# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    class PoolConfig # :nodoc:
      include Mutex_m

      attr_reader :db_config, :connection_specification_name, :schema_cache
      attr_writer :schema_cache

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
        cache = ActiveRecord::ConnectionAdapters::SchemaCache.load_from(db_config.schema_cache_path)
        return if cache.nil?

        current_version = @pool.connection.migration_context.current_version
        return if current_version.nil?

        if cache.version != current_version
          warn "Ignoring #{db_config.schema_cache_path} because it has expired. The current schema version is #{current_version}, but the one in the cache is #{cache.version}."
        else
         @schema_cache = cache
        end
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
