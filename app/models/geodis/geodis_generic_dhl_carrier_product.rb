require "dhl"

class GeodisGenericDHLCarrierProduct < GeodisGenericCarrierProduct
  def supports_automatic_tracking?
    true
  end

  def supports_track_and_trace?
    true
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    DHL.track_and_trace_url(awb: awb)
  end

  def track_shipment(shipment: nil)
    DHLTrackingLib.new.track(credentials: dhl_tracking_credentials, awb: shipment.awb)
  end

  protected

  def dhl_tracking_credentials
    DHLTrackingLib::Credentials.new(
      account: get_credentials.fetch(:dhl_account),
      password: get_credentials.fetch(:dhl_password),
    )
  end
end
