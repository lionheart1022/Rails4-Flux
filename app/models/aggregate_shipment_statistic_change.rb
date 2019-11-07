class AggregateShipmentStatisticChange < ActiveRecord::Base
  class << self
    def process_changes
      self.unhandled.includes(:shipment).each(&:process_change)
    end
  end

  belongs_to :shipment, required: true
  scope :unhandled, -> { where(handled_at: nil) }

  def process_change
    AggregateShipmentStatistic.process_change_for_shipment(shipment)
    update!(handled_at: Time.now)
  end
end
