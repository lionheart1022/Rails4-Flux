class AutobookShipmentDelayedJob

  def initialize(customer_id: nil, shipment_id: nil, carrier_product_autobook_request_id: nil)
    @customer_id                          = customer_id
    @shipment_id                          = shipment_id
    @carrier_product_autobook_request_id  = carrier_product_autobook_request_id
  end

  def enqueue(job)

  end

  def perform
    carrier_product_autobook_request = CarrierProductAutobookRequest.find(@carrier_product_autobook_request_id)
    carrier_product_autobook_request.autobook_shipment
  end

  def before(job)

  end

  def after(job)
  end

  def success(job)

  end

  def error(job, exception)
    carrier_product_autobook_request = CarrierProductAutobookRequest.find(@carrier_product_autobook_request_id)
    carrier_product_autobook_request.handle_error(exception: exception)
  end

  def failure
    carrier_product_autobook_request = CarrierProductAutobookRequest.find(@carrier_product_autobook_request_id)
    carrier_product_autobook_request.handle_error(exception: StandardError.new)
  end

end
