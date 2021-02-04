# frozen_string_literal: true

module ActiveRecord
  module Associations
    # = Active Record Has Many Through Split Association
    class HasManyThroughSplitAssociation < HasManyThroughAssociation # :nodoc:
      def scope
        SplitAssociationScope.create.scope(self)
      end

      def find_target
        scope.to_a
      end
    end
  end
end
