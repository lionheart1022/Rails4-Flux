class PacsoftGenericCarrierProduct < CarrierProduct

  def price_document_class
    PostDKPriceDocument
  end

  def supports_shipment_auto_booking?
    return true
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with POST DK (Pacsoft)')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    PacsoftCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  # Calculates the volume weight for a package of certain dimensions
  # Factor is 1m3 = 280 kg
  #
  # @param dimension [PackageDimension] the dimensions from which to calculate the volume weight
  # @return [Float] The volume weight calculated for the specific product from the dimensions
  def volume_weight(dimension: nil)
    factor = Float((100 * 100 * 100) / 280.0)
    Float(dimension.volume) / Float(factor)
  end

  def supports_track_and_trace?
    true
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    credentials_company = get_credentials[:company]
    "http://www.pacsoftonline.com/ext.po.dk.dk.track?key=#{credentials_company}&reference=#{awb}"
  end

  def external_awb_asset_url(external_awb_asset: nil)
    credentials_company = get_credentials[:company]
    "https://www.pacsoftonline.com/ext.po.dk.dk.linkprint?key=#{credentials_company}&job=#{external_awb_asset}&mode=normal"
  end

  # @return [PacsoftShipperLib::ServiceCodes]
  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end

  # either PDK (Post Danmark) or DPDDK (DPD)
  def partner_id
    raise StandardError.new, "Abstract class. Not implemented"
  end

end

