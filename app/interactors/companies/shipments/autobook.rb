class Companies::Shipments::Autobook < ApplicationInteractor

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

    # determine if allowed to autobook
    raise Companies::Shipments::Autobook::Errors::IllegalActionException.new, "Shipment can only be auto-booked when in created state" unless shipment.state == Shipment::States::CREATED

    # determine if shipment carrier supports auto booking
    raise Companies::Shipments::Autobook::Errors::IllegalActionException.new, "Carrier doesn't support auto-booking" unless carrier_product.supports_shipment_auto_booking?

    # determine if carrier auto booking is enabled for customer
    raise Companies::Shipments::Autobook::Errors::IllegalActionException.new, "Auto-booking disabled on carrier product for customer" unless customer_carrier_product.enable_autobooking

    # book shipment
    carrier_product.auto_book_shipment(company_id: shipment.company_id, customer_id: shipment.customer_id, shipment_id: @shipment_id)
  end

  private

  def check_permissions
    #raise PermissionError.new "You don't have access (TESTING)"
  end
end