module ActiveRecord
  module ModelSchema
    def columns_mapping
      @columns_mapping
    end
    def columns_mapping=(value)
      @columns_mapping = value
    end
    def load_schema!
      @columns_hash = connection.schema_cache.columns_hash(table_name).except(*ignored_columns)
      columns_mapping.each do |k, v|
        if @columns_hash[k].present?
          @columns_hash[v] = @columns_hash.delete k
          @columns_hash[v].instance_variable_set :@name, v
        end
      end

      @columns_hash.each do |name, column|
        define_attribute(
          name,
          connection.lookup_cast_type_from_column(column),
          default: column.default,
          user_provided_default: false
        )
      end
    end
  end
end
