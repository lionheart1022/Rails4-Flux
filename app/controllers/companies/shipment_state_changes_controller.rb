class Companies::ShipmentStateChangesController < CompaniesController
  def create
    @shipment = Shipment.find_company_shipment(company_id: current_company.id, shipment_id: params[:shipment_id])

    interactor =
      Companies::ProcessShipmentStateChange.new(
        company: current_company,
        shipment: @shipment,
        state_change_params: state_change_params,
      )

    interactor.perform!

    respond_to do |format|
      format.js
      format.html { redirect_to companies_shipment_path(@shipment) }
    end
  end

  def bulk_update
    update_params = bulk_update_params
    state = update_params[:state]
    shipment_ids = Array(update_params[:shipment_ids])

    ActiveRecord::Base.transaction do
      shipment_ids.each do |shipment_id|
        shipment = Shipment.find_company_shipment(company_id: current_company.id, shipment_id: shipment_id)
        Companies::ProcessShipmentStateChange.new(company: current_company, shipment: shipment, state_change_params: { state: state }).perform!
      end
    end

    redirect_to params[:redirect_url] || companies_shipments_path, notice: "The selected shipments were updated"
  end

  private

  def state_change_params
    params.fetch(:shipment, {}).permit(
      :state,
      :awb,
      :comment,
    )
  end

  def bulk_update_params
    params.fetch(:bulk_update, {}).permit(
      :state,
      :shipment_ids => [],
    )
  end
end
