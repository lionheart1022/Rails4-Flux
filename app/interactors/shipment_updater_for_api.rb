class ShipmentUpdaterForAPI
  attr_reader :shipment, :api_request

  def initialize(current_context:, shipment:, shipment_params:)
    @current_context = current_context
    @shipment = shipment
    @shipment_params = shipment_params
  end

  def perform
    helper = build_helper
    result = helper.update_shipment_via_api

    @shipment, @api_request = helper.shipment, helper.api_request

    result
  end

  private

  attr_reader :current_context
  attr_reader :shipment_params

  def build_helper
    ShipmentUpdaterHelper.new(
      current_context: current_context,
      shipment: shipment,
      shipment_params: shipment_params,
    )
  end
end
