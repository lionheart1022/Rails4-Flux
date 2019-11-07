class API::V1::Companies::ShipmentsController < API::V1::Companies::CompaniesController

  def index
    page = params[:page]

    shipments = Shipment.includes(:customer, :sender, :recipient, carrier_product: [:carrier], advanced_prices: [:advanced_price_line_items])
      .find_company_shipments(company_id: current_company.id)
      .order(created_at: 'DESC')
      .page(page)

    @view_model = API::V1::Companies::Shipments::ListView.new(company: current_company, shipments: shipments)

    respond_to do |format|
      format.xml
    end
  end

  def show
    shipment_id = params[:id]
    shipment = Shipment.includes(:carrier_product, :sender, :recipient).find_company_shipment_from_unique_shipment_id(company_id: current_company.id, unique_shipment_id: shipment_id)
    advanced_price = AdvancedPrice.find_seller_shipment_price(shipment_id: shipment.try(:id), seller_id: current_company.id, seller_type: Company.to_s)

    @view_model = API::V1::Shared::Shipments::ShowView.new(
      shipment: shipment,
      carrier_product: shipment.try(:carrier_product),
      sender: shipment.try(:sender),
      recipient: shipment.try(:recipient),
      advanced_price: advanced_price,
      show_detailed_price: true
    )

    respond_to do |format|
      format.json
    end
  end

end
