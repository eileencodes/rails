# frozen_string_literal: true

module ActiveRecord
  class SplitAssociationRelation < Relation
    TOO_MANY_RECORDS = 5000

    def initialize(klass, *args)
      key, ids = args
      @ids = ids.uniq
      @key = key
      super(klass)
    end

    def limit(value)
      records.take(value)
    end

    def first(limit = nil)
      if limit
        records.limit(limit).first
      else
        records.first
      end
    end

    def load
      super
      records = @records

      if records.length > TOO_MANY_RECORDS
        warn("You've requested to order #{records.length} in memory. This may have an impact on the performance of this query. Use with caution.")
      end

      records_by_id = records.group_by do |record|
        record[@key]
      end

      records = @ids.flat_map { |id| records_by_id[id] }
      records.compact!

      @records = records
    end
  end
end
