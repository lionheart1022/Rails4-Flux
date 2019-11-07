class ScopedCounter < ActiveRecord::Base
  belongs_to :owner, polymorphic: true, required: true
end
