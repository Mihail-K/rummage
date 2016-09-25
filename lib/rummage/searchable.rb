module Rummage
  module Searchable
    extend ActiveSupport::Concern

    included do
      scope Rummage::Config.search_in_name, -> (*params) {
        all.reveal_in_field_list(params)
      }

      scope Rummage::Config.search_name, -> (params) {
        all.apply_search_and_order(params)
      }
    end
  end
end
