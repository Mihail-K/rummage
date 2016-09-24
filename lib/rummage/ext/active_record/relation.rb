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

      def apply_search_and_order(params)
        return self if params.blank?
        search_with_params(params.except(:_order, '_order'))
        order_with_params(params[:_order] || params['_order'])
      end

      def search_with_params(params)
        return self if params.blank?
        searchable_fields.build_query_params(params)
                         .reject(&:nil?)
                         .each do |query_param|
                           joins!(query_param.joins) if query_param.joins.present?
                         end
                         .map do |query_param|
                           where!(query_param.condition)
                         end
                         .last
      end

      def order_with_params(params)
        return self if params.blank?
        searchable_fields.build_order_params(params)
                         .reject(&:nil?)
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
