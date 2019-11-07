class CarrierPickupRequest < ActiveRecord::Base
  belongs_to :pickup, required: true

  def handled?
    handled_at.present?
  end

  def handle!
    raise "override in subclass"
  end
end
