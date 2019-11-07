require "dhl"

class GTXExpressDocumentDHLCarrierProduct < GTXGenericCarrierProduct
  def service
    GTXShipperLib::Services::GTX_EXPRESS_DHL_EXPORT
  end

  def gtx_shipment_type
    nil
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    DHL.track_and_trace_url(awb: awb)
  end
end
