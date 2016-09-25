Rummage::Builder.define do
  query :not do |field, value|
    if value['not'].is_a?(Array)
      model.arel_table[field].not_in(value['not'])
    else
      model.arel_table[field].not_eq(value['not'])
    end
  end
end
