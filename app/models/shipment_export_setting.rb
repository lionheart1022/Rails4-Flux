class ShipmentExportSetting < ActiveRecord::Base
  module Triggers
    BOOKED     = 'booked'
    IN_TRANSIT = 'in_transit'
    DELIVERED  = 'delivered'
    PROBLEM    = 'problem'
  end

  belongs_to :owner, :polymorphic => true

  class << self
    def find_company_shipment_export_settings_from_shipment(shipment: nil)
      products = CarrierProduct
        .includes([company: :shipment_export_setting])
        .find_carrier_product_chain(carrier_product_id: shipment.carrier_product_id)

      products.map{ |p| p.company.shipment_export_setting }
    end

    def handle_export_triggers(shipment: nil, new_state: nil)
      settings = self.find_company_shipment_export_settings_from_shipment(shipment: shipment)

      settings.each do |setting|
        ShipmentExport.mark_for_export!(owner: setting.owner, shipment_id: shipment.id) if setting && setting.triggered?(new_state)
      end
    end
  end

  def triggered?(state)
    case state
    when Shipment::States::CREATED
      trigger_when_created?
    when Shipment::States::CANCELLED
      trigger_when_cancelled?
    when Shipment::States::BOOKED
      self[Triggers::BOOKED]
    when Shipment::States::IN_TRANSIT
      self[Triggers::IN_TRANSIT]
    when Shipment::States::DELIVERED_AT_DESTINATION
      self[Triggers::DELIVERED]
    when Shipment::States::PROBLEM, Shipment::States::BOOKING_FAILED
      self[Triggers::PROBLEM]
    else
      false
    end
  end
end
