


###################################
###### column casting code ########
###################################
# current only works for querying.
# puts this file to your rails dir: config/initializers/



###+++### comment tag like this means new line code added diff from orignal lib code.

###++
# code inside comment tag like this means new code added diff from orignal lib code.
###



module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SchemaStatements
      def columns(table_name)
        table_name = table_name.to_s
        model = ApplicationRecord.subclasses.find { |e| e.table_name ==  table_name } ###+++###

        column_definitions(table_name).map do |field|
          field[:Field] = model.column_castings[field[:Field]] if model.column_castings[field[:Field]] ###+++###
          new_column_from_field(table_name, field)
        end
      end
    end
  end
end


module ActiveRecord
  class PredicateBuilder # :nodoc:
    def build(attribute, value)
      ####+++
      model = ApplicationRecord.subclasses.find { |e| e.table_name ==  attribute.relation.name }
      if model.column_castings.key(attribute.name)
        attribute.name = model.column_castings.key(attribute.name)
      end
      ###

      if table.type(attribute.name).force_equality?(value)
        bind = build_bind_attribute(attribute.name, value)
        attribute.eq(bind)
      else
        handler_for(value).call(attribute, value)
      end
    end
  end
end


module ActiveRecord
  module ModelSchema
    module ClassMethods
      attr_accessor :columns_hash_uncasted ###+++####

      ###+++
      def column_castings
        @column_castings || {}
      end
      def column_castings=(value)
        @column_castings = value
      end
      ###

      # def load_schema(turn_on_column_casting=true)
      #   return if schema_loaded?
      #   @load_schema_monitor.synchronize do
      #     return if defined?(@columns_hash) && @columns_hash

      #     ####+++
      #     if turn_on_column_casting
      #       load_schema_with_column_casting!
      #     else
      #       load_schema!
      #     end
      #     ###

      #     @schema_loaded = true
      #   rescue
      #     reload_schema_from_cache # If the schema loading failed half way through, we must reset the state.
      #     raise
      #   end
      # end


      def load_schema!
        @columns_hash = connection.schema_cache.columns_hash(table_name).except(*ignored_columns)
        ####+++
        @columns_hash_uncasted = @columns_hash.map do |k, v|
          nk = if column_castings.key(k).present?
                 column_castings.key(k)
               else
                 k
               end
          nv = v.dup
          nv.instance_variable_set :@name, nk
          [nk, nv]
        end.to_h if column_castings.present?
        ###
        @columns_hash.each do |name, column|
          define_attribute(name,
                           connection.lookup_cast_type_from_column(column),
                           default: column.default,
                           user_provided_default: false)
        end
      end
    end
  end
end


module Arel # :nodoc: all
  module Visitors
    class ToSql
      def compile(node, collector = Arel::Collectors::SQLString.new)
        binding.pry

        ###+++
        model = ApplicationRecord.subclasses.find { |e| e.table_name == node.try(:relation).try(:name) }
        if model and model.column_castings.present?
          ncolumns = node.columns.map do |e|
            nname = if model.column_castings.key(e.name).present?
                      model.column_castings.key(e.name)
                    else
                      e
                    end
            e.name = nname
            e
          end
          node.columns = ncolumns

          nexpr = node.values.expr.map do |e|
            e.map do |ee|
              nname = if model.column_castings.key(ee.value.name)
                        model.column_castings.key(ee.value.name)
                      else
                        ee.value.name
                      end
              ee.value.instance_variable_set :@name, nname
              ee
            end
          end
          node.values = nexpr
        end
        ###

        accept(node, collector).value
      end
    end
  end
end
