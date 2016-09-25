module Rummage
  module Searchable
    extend ActiveSupport::Concern

    included do
      scope :search_in, -> (*params) {
        all.reveal_in_field_list(params)
      }

      scope :search, -> (params) {
        all.apply_search_and_order(params)
      }
    end
  end
end
