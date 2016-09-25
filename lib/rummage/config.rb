module Rummage
  module Config
    mattr_accessor :search_in_name do
      :search_in
    end
    mattr_accessor :search_name do
      :search
    end

    mattr_accessor :filter_limit do
      10
    end
    mattr_accessor :order_limit do
      3
    end

    mattr_accessor :order_key do
      '_order'
    end
  end
end
