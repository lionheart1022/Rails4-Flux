class Companies::ShipmentNotesController < CompaniesController
  def update
    @shipment = current_context.find_shipment(params[:shipment_id])
    note = current_context.upsert_shipment_note!(@shipment, params.fetch(:note, {}).permit(:text))

    respond_to do |format|
      format.js { render "admin/shipment_notes/update" }
    end
  end
end
