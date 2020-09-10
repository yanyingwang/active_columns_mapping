module ActiveRecord
  module Querying
    def find_by_sql(sql, binds = [], preparable: nil, &block)
      result_set = connection.select_all(sanitize_sql(sql), "#{name} Load", binds, preparable: preparable)

      ## make columns_mapping work
      result_set.instance_variable_set :@columns, result_set.columns.map { |e|  columns_mapping[e].present? ? columns_mapping[e] : e }

      column_types = result_set.column_types.dup
      attribute_types.each_key { |k| column_types.delete k }
      message_bus = ActiveSupport::Notifications.instrumenter

      payload = {
        record_count: result_set.length,
        class_name: name
      }

      message_bus.instrument("instantiation.active_record", payload) do
        if result_set.includes_column?(inheritance_column)
          result_set.map { |record| instantiate(record, column_types, &block) }
        else
          # Instantiate a homogeneous set
          result_set.map { |record| instantiate_instance_of(self, record, column_types, &block) }
        end
      end
    end
  end
end
