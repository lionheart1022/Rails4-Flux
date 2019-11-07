class APIRequest < ActiveRecord::Base
  belongs_to :shipment

  module Statuses
    FAILED = 'failed'
  end

  before_create :generate_unique_id!, unless: :unique_id?

  def generate_unique_id!
    self.unique_id = SecureRandom.uuid.parameterize
  end
end
