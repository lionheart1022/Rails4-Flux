class Companies::Shipments::RetryConsignmentNote < ApplicationInteractor

  module Errors
    class IllegalActionException < StandardError
    end
  end

  def initialize(company_id: nil, shipment_id: nil)
    @company_id   = company_id
    @shipment_id  = shipment_id

    return self
  end

  def run
    check_permissions

    # find shipment
    shipment        = Shipment.find_company_shipment(company_id: @company_id, shipment_id: @shipment_id)
    carrier_product = shipment.carrier_product
    customer_carrier_product = CustomerCarrierProduct.find_customer_carrier_product(customer_id: shipment.customer_id, carrier_product_id: carrier_product.id)

    # determine if allowed to retry
    raise Companies::Shipments::Autobook::Errors::IllegalActionException.new, "Can only retry consignment note when in waiting for conignment note state" unless shipment.state == Shipment::States::BOOKED_WAITING_CONSIGNMENT_NOTE

    # determine if shipment carrier supports auto booking
    raise Companies::Shipments::Autobook::Errors::IllegalActionException.new, "Carrier doesn't support retrying the consignment note" unless carrier_product.supports_shipment_retry_consignment_note?

    # determine if carrier auto booking is enabled for customer
    raise Companies::Shipments::Autobook::Errors::IllegalActionException.new, "Auto-booking disabled on carrier product for customer" unless customer_carrier_product.enable_autobooking

    # get awb document
    carrier_product.retry_consignment_note(company_id: shipment.company_id, shipment_id: @shipment_id)
  end

  private

  def check_permissions
    #raise PermissionError.new "You don't have access (TESTING)"
  end
end