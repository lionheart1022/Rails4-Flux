module GetCarrierProductsAndPricesForShipment
  extend ActiveSupport::Concern

  private

  def perform_get_carrier_products_and_prices_for_shipment!(company_id:, customer_id:, chain:, custom_products_only:)
    sender_params = params[:sender]
    recipient_params = params[:recipient]
    shipping_date = params[:shipping_date]
    shipment_type = params[:shipment_type]
    is_dangerous_goods = [true, "true"].include?(params[:dangerous_goods])
    is_residential = [true, "true"].include?(params[:residential])
    package_dimensions = params[:package_dimensions]
    goods_lines = params[:goods_lines]

    interactor = Shared::Shipments::GetPrices.new(
      company_id: company_id,
      customer_id: customer_id,
      sender_params: sender_params,
      recipient_params: recipient_params,
      shipping_date: shipping_date,
      shipment_type: shipment_type,
      dangerous_goods: is_dangerous_goods,
      residential: is_residential,
      package_dimensions: package_dimensions,
      goods_lines: goods_lines,
      chain: chain,
      custom_products_only: custom_products_only,
    )

    result = interactor.run

    if e = result.try(:error)
      raise e
    end

    carrier_products_and_prices = result.carrier_products_and_prices
    distance_based_product_is_present = result.distance_based_product_is_present

    html =
      if carrier_products_and_prices && carrier_products_and_prices.length > 0
        render_to_string(partial: "components/customers/shipments/carrier_products_and_prices_for_shipment_table.html.haml", locals: { carrier_products_and_prices: carrier_products_and_prices })
      else
        render_to_string(partial: "components/customers/shipments/no_carrier_products_available.html.haml")
      end

    render json: {
      html: html,
      digest: params[:digest], # digest is used to identify asynchronous ajax requests
      should_show_route: distance_based_product_is_present,
    }
  end
end
