Rummage::Builder.define do
  LIKE_TYPES = %w(string text).freeze

  query :like, types: LIKE_TYPES do |field, value|
    value = ActiveRecord::Base.send(:sanitize_sql_like, value['like'])
    model.arel_table[field].matches("%#{value}%")
  end

  query :starts_with, types: LIKE_TYPES do |field, value|
    value = ActiveRecord::Base.send(:sanitize_sql_like, value['starts_with'])
    model.arel_table[field].matches("#{value}%")
  end

  query :ends_with, types: LIKE_TYPES do |field, value|
    value = ActiveRecord::Base.send(:sanitize_sql_like, value['ends_with'])
    model.arel_table[field].matches("%#{value}")
  end
end
