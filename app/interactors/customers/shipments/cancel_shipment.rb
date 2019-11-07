class Customers::Shipments::CancelShipment < ApplicationInteractor

  def initialize(company_id: nil, customer_id: nil, shipment_id: nil)
    @company_id         = company_id
    @customer_id        = customer_id
    @shipment_id        = shipment_id
    return self
  end

  def run
    shipment = Shipment.find_customer_shipment(company_id: @company_id, customer_id: @customer_id, shipment_id: @shipment_id)
    shipment.cancel(comment: 'Shipment canceled', linked_object: shipment)
    EventManager.handle_event(event: Shipment::ContextEvents::CUSTOMER_CANCEL, event_arguments: { shipment_id: shipment.id })

    return InteractorResult.new(
      shipment: shipment
    )
  rescue => e
    Rails.logger.error("#CancelShipment #{e.inspect}")
    return InteractorResult.new(error: ModelError.new(e.message, shipment))
  end
end
