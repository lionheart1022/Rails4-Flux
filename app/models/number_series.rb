class NumberSeries < ActiveRecord::Base
  scope :active, -> { where disabled_at: nil }
end
