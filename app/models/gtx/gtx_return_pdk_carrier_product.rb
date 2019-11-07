require "post_nord"

class GTXReturnPDKCarrierProduct < GTXGenericCarrierProduct

  def service
    GTXShipperLib::Services::GTX_RETURN_PDK
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    PostNord.track_and_trace_url(awb: awb)
  end

end
