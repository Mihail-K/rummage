
require 'active_record'

require 'rummage/version'
require 'rummage/builder'
require 'rummage/field_list'
require 'rummage/searchable'

require 'rummage/builders/not'
require 'rummage/builders/like'
require 'rummage/builders/inequality'

require 'rummage/ext/active_record/relation'

module Rummage

end

module ActiveRecord
  class Relation
    include RummageExtensions
  end
end
