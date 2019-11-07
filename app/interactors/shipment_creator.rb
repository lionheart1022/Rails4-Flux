class ShipmentCreator
  attr_reader :shipment

  def initialize(current_context:, shipment_params:, initial_shipment_state: Shipment::States::CREATED)
    @current_context = current_context
    @shipment_params = shipment_params
    @initial_shipment_state = initial_shipment_state

    @shipment = nil
  end

  def perform
    helper = build_helper
    result = helper.create_shipment

    @shipment = helper.shipment

    result
  end

  private

  attr_reader :current_context
  attr_reader :shipment_params
  attr_reader :initial_shipment_state

  def build_helper
    ShipmentCreatorHelper.new(
      current_context: current_context,
      shipment_params: shipment_params,
      carrier_product: carrier_product,
      initial_shipment_state: initial_shipment_state,
    )
  end

  def carrier_product
    CarrierProduct
      .where(company: current_context.company)
      .find(shipment_params["carrier_product_id"])
  end
end
