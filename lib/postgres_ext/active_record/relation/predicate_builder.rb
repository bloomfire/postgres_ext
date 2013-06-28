require 'active_record/relation/predicate_builder'

module ActiveRecord
  class PredicateBuilder # :nodoc:
    private

    def self.build(attribute, value)
      case value
      when Array
        engine = attribute.relation.engine
        column = engine.columns.detect{ |col| col.name == attribute.name }
        if column.array
          attribute.eq(value)
        else
          values = value.to_a.map {|x| x.is_a?(Base) ? x.id : x}
          ranges, values = values.partition {|v| v.is_a?(Range)}

          values_predicate = if values.include?(nil)
            values = values.compact

            case values.length
            when 0
              attribute.eq(nil)
            when 1
              attribute.eq(values.first).or(attribute.eq(nil))
            else
              attribute.in(values).or(attribute.eq(nil))
            end
          else
            attribute.in(values)
          end

          array_predicates = ranges.map { |range| attribute.in(range) }
          array_predicates << values_predicate
          array_predicates.inject { |composite, predicate| composite.or(predicate) }
        end
      when ActiveRecord::Relation
        value = value.select(value.klass.arel_table[value.klass.primary_key]) if value.select_values.empty?
        attribute.in(value.arel.ast)
      when Range
        attribute.in(value)
      when ActiveRecord::Base
        attribute.eq(value.id)
      when Class
        # FIXME: I think we need to deprecate this behavior
        attribute.eq(value.name)
      else
        attribute.eq(value)
      end
    end
  end
end
