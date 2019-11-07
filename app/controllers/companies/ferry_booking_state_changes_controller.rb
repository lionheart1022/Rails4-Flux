class Companies::FerryBookingStateChangesController < CompaniesController
  def create
    @shipment = Shipment.find_company_shipment(company_id: current_company.id, shipment_id: params[:shipment_id])

    respond_to do |format|
      format.js
      format.html { redirect_to companies_shipment_path(@shipment) }
    end
  end
end
