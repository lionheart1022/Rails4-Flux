class API::V1::Companies::ShipmentBulkUpdatesController < API::V1::Companies::CompaniesController
  DEFAULT_MAX_NUMBER_OF_UPDATES = 100

  def create
    @update_result = ShipmentBulkUpdate.perform!(
      current_company: current_company,
      payload: update_payload,
      request_id: request.uuid,
      max_number_of_updates: DEFAULT_MAX_NUMBER_OF_UPDATES,
    )

    respond_to do |format|
      format.json
    end
  rescue ShipmentBulkUpdate::ExceededMaximumUpdates, ShipmentBulkUpdate::MissingRequiredParam => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :bad_request }
    end
  end

  private

  def update_payload
    params.permit(
      :updates => [
        :shipment_id,
        :upload_label_from_url,
        :upload_invoice_from_url,
        :upload_consignment_note_from_url,
        :state_change => [:new_state, :comment, :awb],
      ]
    )
  end
end
