Rummage::Builder.define do
  INEQUALITY_TYPES = %w(integer float decimal datetime date time).freeze

  query :lt, :lteq, :gt, :gteq, types: INEQUALITY_TYPES do |field, value|
    %w(lt lteq gt gteq).select { |op| value.key?(op) }
                       .map { |op| model.arel_table[field].send(op, value[op]) }
                       .reject(&:nil?)
                       .reduce(:and)
  end
end
