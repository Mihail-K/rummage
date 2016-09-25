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
        condition = build_query_condition(field, value)
        QueryParam.new(condition, nil) unless condition.nil?
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
        value       = value.deep_stringify_keys
        column_type = model.columns_hash[field].type.to_s

        # Find a registered query builder and construct the query.
        value.keys.map { |name| Rummage::Builder.query_for(name, column_type) }
                  .reject(&:nil?)
                  .first(1)
                  .map { |builder| builder.apply(self, field, value) }
                  .first
      elsif value.is_a?(Array)
        # Generate a field IN (...) query.
        model.arel_table[field].in(value)
      else
        # Generate an exact match query.
        model.arel_table[field].eq(value)
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
