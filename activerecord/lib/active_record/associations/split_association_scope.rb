# frozen_string_literal: true

module ActiveRecord
  module Associations
    class SplitAssociationScope < AssociationScope # :nodoc:
      def self.scope(association)
        INSTANCE.scope(association)
      end

      INSTANCE = create

      def scope(association)
        # source of the through reflection
        source_reflection = association.reflection
        owner = association.owner

        # remove all previously set scopes of passed in association
        scope = association.klass.unscoped

        chain = get_chain(source_reflection, association, scope.alias_tracker)

        reverse_chain = chain.reverse
        first_reflection = reverse_chain.shift
        first_join_ids = [owner.id]

        initial_values = [first_reflection, false, first_join_ids]

        last_reflection, last_ordered, last_join_ids = reverse_chain.inject(initial_values) do |(reflection, ordered, join_ids), next_reflection|
          key =
            if reflection.respond_to?(:join_keys)
              reflection.join_keys.key
            else
              reflection.join_primary_key
            end

          records = add_reflection_constraints(reflection, key, join_ids, owner, ordered)

          foreign_key =
            if next_reflection.respond_to?(:join_keys)
              next_reflection.join_keys.foreign_key
            else
              next_reflection.join_foreign_key
            end

          record_ids = records.pluck(foreign_key)

          records_ordered = records && records.order_values.any?

          [next_reflection, records_ordered, record_ids]
        end

        if last_join_ids.present?
          key =
            if last_reflection.respond_to?(:join_keys)
              last_reflection.join_keys.key
            else
              last_reflection.join_primary_key
            end

          add_reflection_constraints(last_reflection, key, last_join_ids, owner, last_ordered)
        else
          last_reflection.klass.none
        end
      end

      private
        def select_reflection_constraints(reflection, scope_chain_item, owner, scope)
          item = eval_scope(reflection, scope_chain_item, owner)
          scope.unscope!(*item.unscope_values)
          scope.where_clause += item.where_clause
          scope.order_values = item.order_values | scope.order_values
          scope
        end

        def add_reflection_constraints(reflection, key, join_ids, owner, ordered)
          scope = reflection.build_scope(reflection.aliased_table).where(key => join_ids)
          scope = reflection.constraints.inject(scope) do |memo, scope_chain_item|
            select_reflection_constraints(reflection, scope_chain_item, owner, memo)
          end

          if reflection.type
            polymorphic_type = transform_value(owner.class.polymorphic_name)
            scope = apply_scope(scope, reflection.aliased_table, reflection.type, polymorphic_type)
          end

          if scope.order_values.empty? && ordered
            split_scope = SplitAssociationRelation.create(scope.klass, key, join_ids)
            split_scope.where_clause += scope.where_clause
            split_scope
          else
            scope
          end
        end
    end
  end
end
