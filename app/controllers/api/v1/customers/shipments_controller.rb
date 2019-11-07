require "base64"

class API::V1::Customers::ShipmentsController < API::V1::Customers::CustomersController
  def show
    shipment_id = params[:id]
    shipment = Shipment.includes(:carrier_product, :sender, :recipient).find_customer_shipment_from_unique_shipment_id(company_id: current_company.id, customer_id: current_customer.id, unique_shipment_id: shipment_id)
    advanced_price = AdvancedPrice.find_seller_shipment_price(shipment_id: shipment.try(:id), seller_id: current_company.id, seller_type: Company.to_s)

    @view_model = API::V1::Shared::Shipments::ShowView.new(
      shipment: shipment,
      carrier_product: shipment.try(:carrier_product),
      sender: shipment.try(:sender),
      recipient: shipment.try(:recipient),
      advanced_price: advanced_price,
      show_detailed_price: false
    )
  end
end
