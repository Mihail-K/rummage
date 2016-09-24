
require 'active_record'

require 'rummage/version'
require 'rummage/field_list'
require 'rummage/searchable'

require 'rummage/ext/active_record/relation'

module Rummage

end

module ActiveRecord
  class Relation
    include RummageExtensions
  end
end
