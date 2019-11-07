class Companies::ShipmentAutobookRequestsController < CompaniesController
  def show
    @shipment = Shipment.find_company_shipment(company_id: current_company.id, shipment_id: params[:shipment_id])

    scoped_autobook_requests =
      if @shipment.carrier_product.product_responsible == current_company
        CarrierProductAutobookRequest.where(shipment: @shipment)
      else
        CarrierProductAutobookRequest.none
      end

    @autobook_request = scoped_autobook_requests.find(params[:id])
  end
end
