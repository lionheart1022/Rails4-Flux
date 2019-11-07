require "dhl"

class GTXExpressBefore12DHLExportCarrierProduct < GTXGenericCarrierProduct

  def service
    GTXShipperLib::Services::GTX_EXPRESS_BEFORE_12_DHL_EXPORT
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    DHL.track_and_trace_url(awb: awb)
  end

end
