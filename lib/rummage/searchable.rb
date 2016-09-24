module Rummage
  module Searchable
    extend ActiveSupport::Concern

    included do
      scope :reveal, -> (*params) {
        all.reveal_in_field_list(params)
      }

      scope :search, -> (params) {
        all.search_with_params(params)
      }
    end
  end
end
