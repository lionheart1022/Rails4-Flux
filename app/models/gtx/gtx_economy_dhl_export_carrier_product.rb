require "dhl"

class GTXEconomyDHLExportCarrierProduct < GTXGenericCarrierProduct

  def service
    GTXShipperLib::Services::GTX_ECONOMY_DHL_EXPORT
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    DHL.track_and_trace_url(awb: awb)
  end

end
