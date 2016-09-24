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

      def search_with_params(params)
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
    end
  end
end
