require "post_nord"

class GTXPrivateWithTransferPDKCarrierProduct < GTXGenericCarrierProduct

  def service
    GTXShipperLib::Services::GTX_PRIVATE_WITH_TRANSFER_PDK
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    PostNord.track_and_trace_url(awb: awb)
  end

end
