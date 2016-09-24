module Rummage
  class FieldList
    QueryParam = Struct.new(:condition, :joins)
    OrderParam = Struct.new(:condition, :joins)

    attr_reader :model
    attr_reader :name
    attr_reader :prefix

    def initialize(model, name = nil, prefix = '')
      @model  = model
      @name   = name
      @prefix = prefix
    end

    def add_field(field)
      fields << field.to_s if model.column_names.include?(field.to_s)
    end

    def add_association(name, fields)
      return unless name.present? || fields.present?
      association = model.reflect_on_association(name.to_s)
      return if association.nil?

      if (field_list = associations[name.to_s]).nil?
        # Construct a child field-list for the association.
        prefix     = association.plural_name.singularize + '_'
        field_list = associations[name.to_s] = FieldList.new(association.klass, name.to_s, prefix)
      end

      field_list.add_to_field_list(fields)
    end

    def add_to_field_list(fields)
      associations = fields.extract_options!

      fields.flatten.each do |field|
        add_field(field)
      end
      associations.each do |name, fields|
        add_association(name, fields)
      end
    end

    def build_query_params(search)
      search.map do |field, value|
        build_query_for_param(field.to_s, value)
      end
    end

    def build_order_params(orders)
      orders.map do |field, value|
        build_order_for_param(field.to_s, value.to_s)
      end
    end

  protected

    def fields
      @fields ||= Set.new
    end

    def associations
      @associations ||= { }
    end

    def build_query_for_param(field, value)
      if fields.include?(field)
        QueryParam.new(build_query_condition(field, value), nil)
      else
        # Find a field-list with a matching prefix.
        field_list = associations.values.select do |field_list|
          field.starts_with?(field_list.prefix)
        end

        field_list = field_list.first
        return nil if field_list.nil?

        # Search the child field-list for searchable field and construct a query parameter.
        query_param = field_list.build_query_for_param(field.sub(field_list.prefix, ''), value)
        return nil if query_param.nil?

        # Add the current assocation to the joins chain.
        if query_param.joins.nil?
          query_param.joins = field_list.name.to_sym
        else
          query_param.joins = { field_list.name.to_sym => query_param.joins }
        end

        query_param
      end
    end

    def build_query_condition(field, value)
      if value.is_a?(Hash)
        value = value.deep_stringify_keys

        # Negated Queries.
        return build_query_not_condition(field, value) if value.key?('not')

        # Read the column type to determine allowable queries.
        column_type = model.columns_hash[field].type.to_s

        # Relational Queries.
        if %w(integer float decimal datetime time date).include?(column_type)
          result = build_query_relation_condition(field, value)
          return result unless result.nil?
        end

        # Partial Match Queries.
        if %w(string text).include?(column_type)
          result = build_query_like_condition(field, value)
          return result unless result.nil?
        end
      elsif value.is_a?(Array)
        # Generate a field IN (...) query.
        model.arel_table[field].in(value)
      else
        # Generate an exact match query.
        model.arel_table[field].eq(value)
      end
    end

    def build_query_not_condition(field, value)
      if value.is_a?(Array)
        model.arel_table[field].not_in(value['not'])
      else
        model.arel_table[field].not_eq(value['not'])
      end
    end

    def build_query_relation_condition(field, value)
      # Generate queries for all allowed operations.
      queries = %w(lt lteq gt gteq).map do |op|
        model.arel_table[field].send("#{op}", value[op]) if value.key?(op)
      end.reject(&:nil?)

      # Join queries with AND operations.
      return queries.reduce(:and) if queries.present?
    end

    def build_query_like_condition(field, value)
      if value.key?('like')
        # Match with wildcards both before and after the partial.
        partial = ActiveRecord::Base.send(:sanitize_sql_like, value['like'].to_s)
        model.arel_table[field].matches("%#{partial}%")
      elsif value.key?('starts_with')
        # Match with only a wildcard after the partial.
        partial = ActiveRecord::Base.send(:sanitize_sql_like, value['starts_with'].to_s)
        model.arel_table[field].matches("#{partial}%")
      elsif value.key?('ends_with')
        # Match with only a wildcard before the partial.
        partial = ActiveRecord::Base.send(:sanitize_sql_like, value['ends_with'].to_s)
        model.arel_table[field].matches("%#{partial}")
      end
    end

    def build_order_for_param(field, value)
      value = value.downcase
      value = 'asc' unless %(asc desc).include?(value)

      if fields.include?(field)
        OrderParam.new(model.arel_table[field].send(value), nil)
      else
        # Find a field-list with a matching prefix.
        field_list = associations.values.select do |field_list|
          field.starts_with?(field_list.prefix)
        end

        field_list = field_list.first
        return nil if field_list.nil?

        # Search the child field-list for searchable field and construct an order parameter.
        query_param = field_list.build_order_for_param(field.sub(field_list.prefix, ''), value)
        return nil if query_param.nil?

        # Add the current assocation to the joins chain.
        if query_param.joins.nil?
          query_param.joins = field_list.name.to_sym
        else
          query_param.joins = { field_list.name.to_sym => query_param.joins }
        end

        query_param
      end
    end
  end
end
