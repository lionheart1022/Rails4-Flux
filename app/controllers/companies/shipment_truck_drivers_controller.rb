class Companies::ShipmentTruckDriversController < CompaniesController
  def update
    shipment =
      Shipment
      .find_shipments_not_requested
      .find_company_shipment(company_id: current_company.id, shipment_id: params[:shipment_id])

    truck_driver =
      if params[:shipment].try(:[], :truck_driver_id).present?
        TruckDriver.where(company: current_company).find(params[:shipment][:truck_driver_id])
      else
        nil
      end

    shipment.update!(truck_driver: truck_driver)

    redirect_to companies_shipment_path(shipment)
  end
end
