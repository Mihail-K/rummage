module Rummage
  class Builder
    attr_reader :names
    attr_reader :types
    attr_reader :block

    def initialize(names, types, block)
      @names = names
      @types = types
      @block = block
    end

    def self.define(&block)
      instance_eval(&block)
    end

    def self.query_for(name, type)
      builder = query_builders[name.to_s]
      builder if builder.present? && builder.matches_type?(type)
    end

    def self.query(*names, &block)
      types   = names.extract_options![:types]
      builder = Builder.new(names, types, block)

      names.each do |name|
        query_builders[name.to_s] = builder
      end
    end

    def self.query_builders
      @query_builders ||= { }
    end

    def matches_type?(type)
      types.blank? || Array.wrap(types).map(&:to_s).include?(type.to_s)
    end

    def apply(field_list, field, value)
      field_list.instance_exec(field, value, &block)
    end
  end
end
