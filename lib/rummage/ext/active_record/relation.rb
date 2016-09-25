module ActiveRecord
  class Relation
    module RummageExtensions
      def reveal_in_field_list(fields)
        searchable_fields.add_to_field_list(fields)
        self
      end

      def searchable_fields
        @searchable_fields ||= Rummage::FieldList.new(klass)
      end

      def apply_filter_and_order(params)
        return self if params.blank?
        params = params.deep_stringify_keys
        apply_filter_with_params(params.except(Rummage::Config.order_key))
        apply_order_with_params(params[Rummage::Config.order_key])
      end

      def apply_filter_with_params(params)
        return self if params.blank?
        searchable_fields.build_query_params(params)
                         .reject(&:nil?)
                         .first(Rummage::Config.filter_limit.to_i)
                         .each do |query_param|
                           joins!(query_param.joins) if query_param.joins.present?
                         end
                         .map do |query_param|
                           where!(query_param.condition)
                         end
                         .last
      end

      def apply_order_with_params(params)
        return self if params.blank?
        searchable_fields.build_order_params(params)
                         .reject(&:nil?)
                         .first(Rummage::Config.order_limit.to_i)
                         .each do |query_param|
                           joins!(query_param.joins) if query_param.joins.present?
                         end
                         .map do |query_param|
                           order!(query_param.condition)
                         end
                         .last
      end
    end
  end
end
